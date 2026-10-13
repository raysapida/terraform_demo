# ── LAYER 0: NETWORK ──────────────────────────────────────────────────────────
#
# The fix, stated as a rule:
#
#     Anything two stacks both need belongs to neither of them.
#
# Both VPCs and everything that spans them live here, in one state file, owned by
# neither app team. The app stacks below consume this layer; they never reference
# each other.
#
# This is what breaks the deadlock. In 01-broken, pipeline needed portal's VPC and
# portal needed pipeline's — a cycle with no valid apply order. Here there is
# exactly one order: network, then the app stacks in either order.
#
# Everything gets a Name tag. That is not cosmetic: tags are the lookup key the
# app stacks use instead of hardcoded IDs.

resource "aws_vpc" "pipeline" {
  cidr_block           = var.pipeline_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sacjs-pipeline-vpc"
    Tier = "pipeline"
  }
}

resource "aws_vpc" "portal" {
  cidr_block           = var.portal_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sacjs-portal-vpc"
    Tier = "portal"
  }
}

resource "aws_subnet" "pipeline_private_1" {
  vpc_id            = aws_vpc.pipeline.id
  cidr_block        = cidrsubnet(var.pipeline_cidr, 8, 1)
  availability_zone = "us-east-1a"
  tags = {
    Name = "sacjs-pipeline-private-1"
    Tier = "pipeline"
  }
}

resource "aws_subnet" "pipeline_private_2" {
  vpc_id            = aws_vpc.pipeline.id
  cidr_block        = cidrsubnet(var.pipeline_cidr, 8, 2)
  availability_zone = "us-east-1b"
  tags = {
    Name = "sacjs-pipeline-private-2"
    Tier = "pipeline"
  }
}

resource "aws_subnet" "portal_public_1" {
  vpc_id                  = aws_vpc.portal.id
  cidr_block              = cidrsubnet(var.portal_cidr, 8, 10)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "sacjs-portal-public-1"
    Tier = "portal"
  }
}

# ── Where the peering connection would live ───────────────────────────────────
#
# In real AWS this is the whole point of the layer: the peering connection spans
# both VPCs, so it belongs to neither app stack, and here it has unambiguous
# access to both VPC IDs as first-class references — no hardcoded IDs, no cycle:
#
#   resource "aws_vpc_peering_connection" "pipeline_to_portal" {
#     vpc_id      = aws_vpc.pipeline.id
#     peer_vpc_id = aws_vpc.portal.id
#     auto_accept = true
#   }
#
# Compare that to 01-broken, where the same relationship needed two hardcoded IDs
# in two state files and could not be applied from scratch at all.
#
# It is commented out because Floci 2.0.1 returns UnsupportedOperation for
# CreateVpcPeeringConnection (see docs/FINDINGS.md). Uncomment it against real
# AWS and it works. The demo proves the *pattern* with security groups, which
# Floci does support and which fail identically when hardcoded.

output "pipeline_vpc_id" {
  value = aws_vpc.pipeline.id
}

output "portal_vpc_id" {
  value = aws_vpc.portal.id
}

output "pipeline_subnet_ids" {
  value = [aws_subnet.pipeline_private_1.id, aws_subnet.pipeline_private_2.id]
}
