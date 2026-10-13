# ── PIPELINE STACK (the broken version) ───────────────────────────────────────
#
# This mirrors the real fitscale-pipeline Terraform. The data-processing side:
# its own VPC, its own RDS, and a security group that lets the *portal* stack's
# VPC reach Postgres.
#
# The bug this stack demonstrates: it references the portal's VPC by a HARDCODED
# ID that lives in a completely different Terraform state file.
#
#   Real source: fitscale-pipeline/main.tf:869
#     peer_vpc_id = "vpc-0aaaaaaaaaaaaaaaa"
#
# Nothing in this configuration can create that VPC, and nothing verifies it
# exists. It works only because someone ran the other stack first, by hand, once,
# years ago.

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "pipeline-rds-vpc"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pipeline-rds-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "pipeline-rds-private-subnet-2"
  }
}

# ── The first hardcoded coupling ──────────────────────────────────────────────
# The portal's CIDR, as a string literal, documented only by a comment.
# Real source: fitscale-pipeline/main.tf:406
#   cidr_blocks = ["10.1.0.0/16"] # New Rails App VPC CIDR
#
# If the portal stack ever changes its CIDR, this silently stops matching and
# the Rails app loses its database. Nothing fails at plan time.
resource "aws_security_group" "rds" {
  name   = "pipeline-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"] # Portal VPC CIDR — hardcoded, unverified
    description = "Allow portal VPC via peering"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pipeline-rds-security-group"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "pipeline-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Floci spawns a real postgres:15.17-alpine container for this. ~90s.
resource "aws_db_instance" "postgres" {
  identifier             = "pipeline-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.17"
  instance_class         = "db.t3.micro"
  db_name                = "pipeline_database"
  username               = "pipeline_user"
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true
  publicly_accessible    = true # so the demo can psql to it; not how prod is set up
}

# ── The second hardcoded coupling ─────────────────────────────────────────────
# This is the one that actually breaks. `terraform apply` fails here with
# InvalidVpcID.NotFound, because this VPC belongs to a different state file —
# and in a fresh account, it has never existed at all.
#
# Real source: fitscale-pipeline/main.tf:867-875
#
# Floci does not emulate VPC peering (see docs/FINDINGS.md), so we demonstrate
# the identical bug with an operation it *does* support: attaching to a VPC by
# hardcoded ID. Same failure, same lesson, and it actually runs.
resource "aws_security_group" "cross_stack" {
  name = "pipeline-to-portal"

  # ⚠️ THE BUG. This ID is owned by 02-portal's state file.
  vpc_id = "vpc-0aaaaaaaaaaaaaaaa"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Return path from portal VPC to pipeline"
  }

  tags = {
    Name = "pipeline-to-portal-return"
  }
}

# The output that exists and that nobody consumes.
# Real source: fitscale-pipeline/outputs.tf:1-3
#
# Somebody knew the right shape. The wiring never got built.
output "pipeline_vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
