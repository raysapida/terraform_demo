# ── PIPELINE STACK (fixed) ────────────────────────────────────────────────────
#
# Identical infrastructure to stacks/05-shared-ownership/01-broken/pipeline. The only difference is how it
# finds out what the network layer built: it LOOKS THINGS UP instead of
# hardcoding them.
#
# Three things follow from that, and they're the payoff of the whole talk:
#
#   1. No IDs in this file. Nothing to go stale.
#   2. Applying this before the network layer produces a real, immediate error
#      ("no matching EC2 VPC found") instead of silently drifting.
#   3. This stack no longer references the portal stack AT ALL. The cycle is gone,
#      because the shared thing moved to a layer that owns it.

# ── The fix, in four lines ────────────────────────────────────────────────────
# Compare to stacks/05-shared-ownership/01-broken/pipeline/main.tf:112 — `vpc_id = "vpc-0aaaaaaaaaaaaaaaa"`
data "aws_vpc" "pipeline" {
  filter {
    name   = "tag:Name"
    values = ["sacjs-pipeline-vpc"]
  }
}

data "aws_subnets" "pipeline_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.pipeline.id]
  }
}

# The portal's CIDR is read from the network layer's actual state of the world,
# not copied into a comment. If it changes, this follows automatically.
data "aws_vpc" "portal" {
  filter {
    name   = "tag:Name"
    values = ["sacjs-portal-vpc"]
  }
}

resource "aws_security_group" "rds" {
  name   = "pipeline-rds-sg-fixed"
  vpc_id = data.aws_vpc.pipeline.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.portal.cidr_block] # ← looked up, not hardcoded
    description = "Allow portal VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pipeline-rds-sg-fixed"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "pipeline-db-subnet-group-fixed"
  subnet_ids = data.aws_subnets.pipeline_private.ids
}

resource "aws_db_instance" "postgres" {
  identifier             = "pipeline-db-fixed"
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
  publicly_accessible    = true
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}
