# ── STACK 1: STATIC SITE ──────────────────────────────────────────────────────
#
# The smallest real environment: a private bucket holds the files, a CDN serves
# them. Five resources, and every JS developer in the room has shipped this
# shape — usually by clicking "deploy" somewhere that hid all five.
#
# The one idea this stack teaches: the CDN is just another resource. Terraform
# does not care that CloudFront is "global" and S3 is "regional". It is a graph
# of API calls, and this one is short.
#
# Note what is NOT here: no VPC, no subnets, no security groups, no servers.
# Hold that thought for stack 3, where the network is most of the file.

variable "site_name" {
  description = "Bucket name. Must be globally unique on real AWS; anything goes on Floci."
  type        = string
  default     = "sacjs-static-site"
}

# ── Where the files live ──────────────────────────────────────────────────────
# Private. Nobody reads this bucket directly, and there is deliberately no
# website configuration. The only reader is the distribution below, and the
# bucket policy says so. (Floci's default settings do not enforce any of that;
# see the bucket policy below.)
resource "aws_s3_bucket" "site" {
  bucket        = var.site_name
  force_destroy = true # demo only: lets `make clean` delete a non-empty bucket
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── How the CDN proves who it is ──────────────────────────────────────────────
# Origin access control: CloudFront signs its requests to S3. This replaced the
# older "origin access identity" in 2022; tutorials still show OAI, and it still
# works, which is how old patterns survive.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.site_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── The CDN ───────────────────────────────────────────────────────────────────
# On real AWS this apply takes 5–15 minutes while the config propagates to edge
# locations. Floci reports "Deployed" immediately — one of the places the
# emulator is faster than the thing it emulates.
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    origin_id                = "s3-site"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # AWS's managed "CachingOptimized" policy. A literal ID, but AWS owns it and
    # it is the same in every account — not the cross-state hardcoding bug from
    # 01-broken, where the ID belongs to someone else's state file.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # ── An ignore_changes, and exactly what it is hiding ──
  # Floci 2.0.1 does not store tags on distributions and returns cached_methods
  # empty, so without this every plan shows a change that no apply can fix.
  # Both are EMULATOR drift, not config drift. Against real AWS, delete this
  # block — the talk's own rule is that ignore_changes suppresses feedback, and
  # on real AWS that feedback would be true.
  lifecycle {
    ignore_changes = [tags_all, default_cache_behavior[0].cached_methods]
  }
}

# ── The one line of trust ─────────────────────────────────────────────────────
# Read access for the CloudFront service, and only when the request comes from
# THIS distribution (AWS:SourceArn). Delete this resource and the site 403s —
# the bucket is private, and the CDN has no other way in.
#
# ⚠️ On Floci that is only true with FLOCI_SERVICES_S3_ENFORCE_AUTH=true and
# FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true. Both default to off, and then the
# policy and the public access block are stored but never evaluated: anonymous
# reads succeed and the site serves without this resource. Measured both ways
# on 2026-09-12 — see docs/FINDINGS.md. The objects are real; the policy is not,
# unless you ask for it.
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn }
      }
    }]
  })

  # The public access block must exist first, or S3 may evaluate the policy
  # against a bucket that has not finished locking down.
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# ── What the deploy step needs ────────────────────────────────────────────────
# Terraform provisions the bucket; it does not upload the site. Uploading is the
# deploy axis — `make site` runs `aws s3 sync` against this output. Same seam as
# Kamal reading `terraform output` in stack 3, in its smallest possible form.
output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "site_url" {
  value = "https://${aws_cloudfront_distribution.site.domain_name}/"
}
