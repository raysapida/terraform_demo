# CIDRs are defined once, here, and consumed by both app stacks via data sources.
# In 01-broken these same values appear as string literals in two repos, each
# documented only by a comment naming the other project.
variable "pipeline_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "portal_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
