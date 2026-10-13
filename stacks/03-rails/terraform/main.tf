# ── STACK 3: RAILS + POSTGRES + S3 ────────────────────────────────────────────
#
# What a conventional Rails app needs to exist: somewhere to run, a database,
# and a bucket for uploads. Count the resources by section as you read:
#
#   network   VPC, internet gateway, route table, three subnets, two SGs
#   compute   key pair, the app host
#   database  subnet group, password, RDS instance
#   uploads   bucket, public access block
#   access    IAM user, access key, policy
#
# The one idea this stack teaches: MOST OF THE TERRAFORM IS NETWORK. The thing
# you actually care about — Postgres — is one resource. Getting it somewhere
# private, reachable only by the app, is the rest. Stack 1 had none of this.
#
# The app host is here as it would be on real AWS: an aws_instance in the public
# subnet, behind the app security group, with SSH open to one address for Kamal.
# On the laptop Floci creates it too (an Ubuntu container), but Kamal still
# deploys to the stand-in host in ../host (sshd + Docker CLI): Docker inside
# Floci's instance needs extra steps that are not wired up yet (docs/FINDINGS.md).

variable "name" {
  type    = string
  default = "sacjs-rails"
}

# Kamal SSHes to the host from wherever you run `kamal deploy`. On real AWS set this
# to your own address as a /32 (curl -s https://checkip.amazonaws.com). The default
# is a documentation address, so SSH is not open to the world by accident.
variable "ssh_cidr" {
  type    = string
  default = "203.0.113.10/32"
}

# The demo's deploy key. `make rails` generates it before provisioning.
variable "ssh_public_key_path" {
  type    = string
  default = "../host/state/id_ed25519.pub"
}

variable "cidr" {
  type    = string
  default = "10.20.0.0/16"
}

# ══ NETWORK ═══════════════════════════════════════════════════════════════════

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name}-vpc" }
}

# The app host lives in a public subnet so users can reach it and Kamal can SSH
# to it. That takes three resources: the subnet, a gateway, and a route to it.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, 1)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# The database lives in private subnets: no route to the internet gateway.
# RDS insists on at least two availability zones even for a single instance,
# which is why a one-database app needs two subnets.
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, 10 + count.index)
  availability_zone = ["us-east-1a", "us-east-1b"][count.index]
  tags              = { Name = "${var.name}-private-${count.index + 1}" }
}

resource "aws_security_group" "app" {
  name   = "${var.name}-app"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for Kamal, from one address only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-app" }
}

# Postgres accepts connections from the app's security group — not from a CIDR.
# Same idea as 02-fixed: refer to the thing, never copy its address.
resource "aws_security_group" "db" {
  name   = "${var.name}-db"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Postgres from the app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = { Name = "${var.name}-db" }
}

# ══ COMPUTE ═══════════════════════════════════════════════════════════════════
# The app host Kamal deploys to: Ubuntu 24.04 on arm64 (matching deploy.yml's
# builder arch), in the public subnet, behind the app security group.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.name}-deploy"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.small"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deploy.key_name

  # Kamal needs Docker on the host; this installs it at first boot. (Floci runs
  # it too, but its instance has no systemd, so dockerd does not start on its own.)
  user_data = <<-EOF
    #!/bin/sh
    curl -fsSL https://get.docker.com | sh
  EOF

  tags = { Name = "${var.name}-app" }
}

# ══ DATABASE ══════════════════════════════════════════════════════════════════

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db"
  subnet_ids = aws_subnet.private[*].id
}

# Compare stacks/05-shared-ownership/02-fixed/pipeline/variables.tf, where the password is a default value
# in git. Here it is generated. It still ends up in terraform.tfstate in plain
# text — `sensitive` only hides it from the terminal (talk §5e).
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_instance" "main" {
  identifier             = "${var.name}-db"
  engine                 = "postgres"
  engine_version         = "15.17"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "rails_production"
  username               = "rails"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true # demo only: lets `make clean` destroy it
}

# ══ UPLOADS ═══════════════════════════════════════════════════════════════════

resource "aws_s3_bucket" "uploads" {
  bucket        = "${var.name}-uploads"
  force_destroy = true # demo only
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ══ ACCESS ════════════════════════════════════════════════════════════════════

# How a Kamal-deployed app usually gets S3 access: an IAM user with a long-lived
# key, passed in as a secret. It's the shape the real repo uses (talk §5e).
# On EC2 an instance role avoids the long-lived key; this stack has no instance.
resource "aws_iam_user" "app" {
  name = "${var.name}-app"
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

# Scoped to one bucket. The wildcard version — s3:* on * — is the one people
# ship, and Floci would accept it just as happily (see docs/FINDINGS.md).
resource "aws_iam_user_policy" "app_uploads" {
  name = "uploads-bucket"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.uploads.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      },
    ]
  })
}

# ══ OUTPUTS: the seam ═════════════════════════════════════════════════════════
# Everything the app needs to boot. Kamal reads these at deploy time:
# app/config/deploy.yml for plain settings, app/.kamal/secrets for the
# password and the access key. Nothing is copied into config/ by hand.

# On real AWS, deploy.yml's host would read this. On the laptop Kamal targets the
# stand-in host at 127.0.0.1 instead.
output "app_host_ip" {
  value = aws_instance.app.public_ip
}

output "db_host" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_user" {
  value = aws_db_instance.main.username
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "s3_bucket" {
  value = aws_s3_bucket.uploads.id
}

output "app_access_key_id" {
  value = aws_iam_access_key.app.id
}

output "app_secret_access_key" {
  value     = aws_iam_access_key.app.secret
  sensitive = true
}
