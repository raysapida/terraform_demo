# ── PORTAL STACK (the broken version) ─────────────────────────────────────────
#
# Mirrors the real fit-scale-portal Terraform. The Rails side: its own VPC,
# public subnets, and the accepter half of the cross-stack link.
#
# The bug: this stack references, by hardcoded ID, a resource created by the
# *pipeline* stack — which in turn references this stack's VPC by hardcoded ID.
#
#   Real source: fit-scale-portal/deploy/terraform/main.tf:57
#     vpc_peering_connection_id = "pcx-0bbbbbbbbbbbbbbbb"
#
# Read that alongside stacks/05-shared-ownership/01-broken/pipeline/main.tf and the deadlock is visible:
#
#   pipeline needs  vpc-0aaaaaaaaaaaaaaaa  ← created by portal
#   portal   needs  pcx-0bbbbbbbbbbbbbbbb  ← created by pipeline
#
# Neither can go first. The configuration can only describe infrastructure that
# already exists; it cannot create it.

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Note: no Name tag. In the real repo the portal VPC is untagged, which is
  # precisely why the pipeline had to reference it by raw ID instead of looking
  # it up. stacks/05-shared-ownership/02-fixed/ adds the tag and the problem dissolves.
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "app" {
  name   = "portal-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # The real repo also opens 22 to 0.0.0.0/0
  # (fit-scale-portal/deploy/terraform/main.tf:76-80). Left out here on purpose —
  # mention it on the slide, don't ship it in a repo people will clone.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── The reciprocal hardcoded coupling ─────────────────────────────────────────
# The other half of the deadlock. This security group attaches to a VPC owned by
# the pipeline stack's state file.
#
# Real source: fit-scale-portal/deploy/terraform/main.tf:56-58 (the peering
# accepter, hardcoding pcx-0bbbbbbbbbbbbbbbb).
resource "aws_security_group" "cross_stack" {
  name = "portal-to-pipeline"

  # ⚠️ THE BUG, from the other direction. Owned by stacks/05-shared-ownership/01-broken/pipeline's state.
  vpc_id = "vpc-0ccccccccccccccc"

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Reach pipeline Postgres"
  }

  tags = {
    Name = "portal-to-pipeline"
  }
}

output "portal_vpc_id" {
  value = aws_vpc.main.id
}
