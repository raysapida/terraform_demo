# ── PORTAL STACK (fixed) ──────────────────────────────────────────────────────
#
# Same shape as the pipeline stack: look everything up, hardcode nothing, and
# never mention the other app stack.
#
# In 01-broken this file hardcoded vpc-0ccccccccccccccc — an ID owned by the
# pipeline's state file — and `terraform apply` died with InvalidVpcID.NotFound.

data "aws_vpc" "portal" {
  filter {
    name   = "tag:Name"
    values = ["sacjs-portal-vpc"]
  }
}

data "aws_vpc" "pipeline" {
  filter {
    name   = "tag:Name"
    values = ["sacjs-pipeline-vpc"]
  }
}

resource "aws_security_group" "app" {
  name   = "portal-app-sg-fixed"
  vpc_id = data.aws_vpc.portal.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reach the pipeline's Postgres. The CIDR is read from the live network layer,
  # so it cannot drift out of sync with what the pipeline actually built.
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.pipeline.cidr_block]
    description = "Reach pipeline Postgres"
  }

  tags = {
    Name = "portal-app-sg-fixed"
  }
}

output "portal_vpc_id" {
  value = data.aws_vpc.portal.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}
