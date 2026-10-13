# ── STACK 2: LAMBDA + DYNAMODB ────────────────────────────────────────────────
#
# A small HTTP API: a function, a table, and a URL. Count the resources:
#
#   data      table
#   code      zip (a data source), function, log group
#   access    execution role, table policy, logs policy
#   http      function URL, two permissions
#
# The one idea this stack teaches: THE NETWORK DISAPPEARS, AND IAM BECOMES THE
# STACK. Put this file next to stacks/03-rails/terraform/main.tf. No VPC, no
# subnets, no security groups, no gateway — AWS runs the function somewhere you
# never see. What's left to get wrong is who is allowed to do what: three of the
# nine resources are IAM, and the two permissions at the bottom are IAM too.

variable "name" {
  type    = string
  default = "sacjs-lambda"
}

# ══ DATA ══════════════════════════════════════════════════════════════════════

# On-demand billing: no capacity to size, no charge when idle. The whole schema
# is the key; DynamoDB does not care what else is in an item.
resource "aws_dynamodb_table" "messages" {
  name         = "${var.name}-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ══ CODE ══════════════════════════════════════════════════════════════════════

# Terraform zips ../function at plan time. Change the handler and the hash
# changes, so the next apply uploads new code. That's the whole deploy axis for
# this stack, folded into provisioning — compare stack 1's `aws s3 sync` and
# stack 3's `bin/deploy`.
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/../function"
  output_path = "${path.module}/.build/function.zip"
}

resource "aws_lambda_function" "api" {
  function_name    = var.name
  role             = aws_iam_role.function.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.messages.name
    }
  }

  # The log group must exist before the first invoke, or Lambda creates one
  # itself — outside Terraform, with no retention, kept forever.
  depends_on = [aws_cloudwatch_log_group.function]
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
}

# ══ ACCESS ════════════════════════════════════════════════════════════════════

# The identity the function runs as. The trust policy says only the Lambda
# service may assume it. This replaces stack 3's IAM user and its long-lived
# key: nothing to leak, nothing to rotate.
resource "aws_iam_role" "function" {
  name = "${var.name}-function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Two actions on one table. The version people actually ship is
#   Action = "dynamodb:*", Resource = "*"
# and on stock Floci it works identically — IAM is stored, not evaluated (see
# docs/FINDINGS.md). On real AWS the difference is whether a bug in this
# function can delete every table in the account.
resource "aws_iam_role_policy" "table" {
  name = "messages-table"
  role = aws_iam_role.function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:Scan"]
      Resource = aws_dynamodb_table.messages.arn
    }]
  })
}

# What the AWSLambdaBasicExecutionRole managed policy grants, scoped to this
# function's own log group instead of every log group in the account.
resource "aws_iam_role_policy" "logs" {
  name = "own-log-group"
  role = aws_iam_role.function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.function.arn}:*"
    }]
  })
}

# ══ HTTP ══════════════════════════════════════════════════════════════════════

# A public HTTPS endpoint for one function, with no API Gateway. (Floci's API
# Gateway v2 quick-create does not route requests — docs/FINDINGS.md — and a
# function URL is less Terraform anyway.)
resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
}

# "Public" still needs a resource policy. Since October 2025 new function URLs
# need TWO statements even with auth NONE: invoke the URL, and invoke the
# function via the URL. Omit either and callers get 403 Forbidden. The console
# and SAM add both for you; Terraform, the CLI and CloudFormation do not — so
# anything copied from a pre-2025 tutorial is missing the second one.
# (docs.aws.amazon.com/lambda/latest/dg/urls-auth.html)
resource "aws_lambda_permission" "url" {
  statement_id           = "public-function-url"
  function_name          = aws_lambda_function.api.function_name
  action                 = "lambda:InvokeFunctionUrl"
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "invoke_via_url" {
  statement_id             = "public-invoke-via-url"
  function_name            = aws_lambda_function.api.function_name
  action                   = "lambda:InvokeFunction"
  principal                = "*"
  invoked_via_function_url = true
}

# ══ OUTPUTS ═══════════════════════════════════════════════════════════════════

output "function_url" {
  value = aws_lambda_function_url.api.function_url
}

output "table_name" {
  value = aws_dynamodb_table.messages.name
}
