# ── STACK 4: TANSTACK START, SERVERLESS ───────────────────────────────────────
#
# A full-stack TypeScript framework with server rendering. The one idea this
# stack teaches: NOTHING NEW. Nitro's aws_lambda preset splits the build into
# two directories, and each lands on a stack the room has already seen:
#
#   app/.output/public   static assets  → private S3 + CloudFront + OAC  (stack 1)
#   app/.output/server   SSR handler    → Lambda + role + function URL   (stack 2)
#
# The only genuinely new resource is what joins them: one CloudFront
# distribution with two origins, routing /assets/* to S3 and everything else
# to the function.
#
# ⚠️ Floci edges this stack runs into (docs/FINDINGS.md, measured):
#   - CloudFront refuses custom origins that resolve to loopback unless the host
#     is allowlisted. docker-compose.yml allowlists this function's URL host,
#     which Floci derives from the function name — rename the function and the
#     allowlist must change too.
#   - Floci's CloudFront proxies only GET/HEAD/OPTIONS to the function, and drops
#     the query string. So the app renders everything on the server and makes
#     no client-side server-function calls. This Terraform is right for real
#     AWS, where POSTs and query strings pass through.

variable "name" {
  type    = string
  default = "sacjs-tanstack"
}

locals {
  build_dir = "${path.module}/../app/.output"

  # Nitro fingerprints asset filenames, so they can be cached forever: a new
  # build produces new names instead of changing old ones.
  content_types = {
    css   = "text/css"
    js    = "text/javascript"
    json  = "application/json"
    svg   = "image/svg+xml"
    png   = "image/png"
    ico   = "image/x-icon"
    woff2 = "font/woff2"
    txt   = "text/plain"
  }

  # Split the function URL into what CloudFront needs. On real AWS it is
  # https://<id>.lambda-url.<region>.on.aws/ ; on Floci it is
  # http://<id>.lambda-url.<region>.localhost:4566/ . Same expression for both.
  fn_url      = regex("^(https?)://([^/:]+)(?::([0-9]+))?/", aws_lambda_function_url.ssr.function_url)
  fn_protocol = local.fn_url[0]
  fn_host     = local.fn_url[1]
  fn_port     = coalesce(local.fn_url[2], local.fn_protocol == "https" ? "443" : "80")
}

# ══ STATIC ASSETS — stack 1's shape ═══════════════════════════════════════════

resource "aws_s3_bucket" "assets" {
  bucket        = "${var.name}-assets"
  force_destroy = true # demo only
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Uploaded by Terraform rather than `aws s3 sync` (compare stack 1), for one
# reason: ordering. The function below depends on these objects, so a deploy
# uploads the new CSS and JS BEFORE the new HTML that references them goes live.
# Sync after apply, and every deploy has a window of unstyled pages.
resource "aws_s3_object" "assets" {
  for_each = fileset("${local.build_dir}/public", "**")

  bucket        = aws_s3_bucket.assets.id
  key           = each.value
  source        = "${local.build_dir}/public/${each.value}"
  etag          = filemd5("${local.build_dir}/public/${each.value}")
  content_type  = lookup(local.content_types, reverse(split(".", each.value))[0], "application/octet-stream")
  cache_control = startswith(each.value, "assets/") ? "public, max-age=31536000, immutable" : "public, max-age=60"
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.name}-assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.assets.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.assets]
}

# ══ SERVER RENDERING — stack 2's shape ════════════════════════════════════════

# Zips Nitro's server output. `make tanstack` builds the app before plan, so
# this always matches the assets above.
data "archive_file" "server" {
  type        = "zip"
  source_dir  = "${local.build_dir}/server"
  output_path = "${path.module}/.build/server.zip"
}

resource "aws_iam_role" "ssr" {
  name = "${var.name}-ssr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# The SSR function touches no AWS service, so its only permission is its own
# logs. Compare stack 2, which needed a table policy as well.
resource "aws_iam_role_policy" "logs" {
  name = "own-log-group"
  role = aws_iam_role.ssr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.ssr.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "ssr" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "ssr" {
  function_name    = var.name
  role             = aws_iam_role.ssr.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.server.output_path
  source_code_hash = data.archive_file.server.output_base64sha256
  memory_size      = 512 # rendering React is CPU work; Lambda CPU scales with memory
  timeout          = 10

  environment {
    variables = {
      NODE_ENV = "production"
    }
  }

  depends_on = [aws_cloudwatch_log_group.ssr, aws_s3_object.assets]
}

resource "aws_lambda_function_url" "ssr" {
  function_name      = aws_lambda_function.ssr.function_name
  authorization_type = "NONE"
}

# The same two statements as stack 2, for the same October 2025 reason.
# In production you would put AWS_IAM on the URL and let CloudFront sign
# requests with a Lambda origin access control, so the URL is not public. That
# is two more resources, and not something Floci can enforce anyway.
resource "aws_lambda_permission" "url" {
  statement_id           = "public-function-url"
  function_name          = aws_lambda_function.ssr.function_name
  action                 = "lambda:InvokeFunctionUrl"
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "invoke_via_url" {
  statement_id             = "public-invoke-via-url"
  function_name            = aws_lambda_function.ssr.function_name
  action                   = "lambda:InvokeFunction"
  principal                = "*"
  invoked_via_function_url = true
}

# ══ THE JOIN — the only new idea ═════════════════════════════════════════════

resource "aws_cloudfront_distribution" "site" {
  enabled = true
  comment = "${var.name}: /assets/* from S3, everything else from Lambda"

  origin {
    origin_id                = "assets"
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  origin {
    origin_id   = "ssr"
    domain_name = local.fn_host

    custom_origin_config {
      http_port              = local.fn_protocol == "http" ? tonumber(local.fn_port) : 80
      https_port             = local.fn_protocol == "https" ? tonumber(local.fn_port) : 443
      origin_protocol_policy = "${local.fn_protocol}-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Fingerprinted files: cache at the edge for a year.
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "assets"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # managed: CachingOptimized
  }

  # Everything else is a server render: never cached, every method allowed,
  # every viewer header forwarded EXCEPT Host. A function URL routes on its own
  # hostname, so forwarding the viewer's Host would make Lambda reject the
  # request. That one managed policy is the classic CloudFront-to-Lambda bug.
  default_cache_behavior {
    target_origin_id         = "ssr"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # managed: CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # managed: AllViewerExceptHostHeader
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Floci-only drift. As in stack 1, distribution tags are not stored and
  # cached_methods come back empty. New here: a custom origin's keepalive
  # timeout, read timeout and TLS protocols come back as 0/empty, and because
  # `origin` is a set it can only be ignored whole.
  #
  # Which is exactly the talk's warning about ignore_changes, live: this also
  # hides a REAL origin change. It is survivable here only because the function
  # URL host is stable for a given function name. Delete this block against
  # real AWS.
  lifecycle {
    ignore_changes = [
      tags_all,
      origin,
      default_cache_behavior[0].cached_methods,
      ordered_cache_behavior[0].cached_methods,
    ]
  }
}

# ══ OUTPUTS ═══════════════════════════════════════════════════════════════════

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "site_url" {
  value = "https://${aws_cloudfront_distribution.site.domain_name}/"
}

output "function_url" {
  value = aws_lambda_function_url.ssr.function_url
}

# What docker-compose.yml must allowlist for Floci's CloudFront to reach the
# function. Stable for a given function name.
output "function_url_host" {
  value = local.fn_host
}
