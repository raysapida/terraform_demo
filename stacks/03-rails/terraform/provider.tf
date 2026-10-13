# Points the standard hashicorp/aws provider at Floci instead of real AWS.
# Nothing here is Floci-specific except the endpoint URLs — this is the same
# `endpoints` block you'd use against any AWS-compatible emulator.
#
# NOTE: state is local (no S3 backend) so the demo has no setup step. The real
# FitScale stacks use separate S3 backends; see docs/FINDINGS.md.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.x, like every stack under stacks/. See 01-static-site/provider.tf
      # for why 5.x is not an option against Floci.
      version = "~> 6.0"
    }
    # Generates the database password, so no default ever sits in git.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "floci_endpoint" {
  description = "Floci endpoint. Override to point at real AWS (don't)."
  type        = string
  default     = "http://localhost:4566"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  # Emulator has no real IAM/STS to validate against.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  default_tags {
    tags = {
      Project   = "SACJS-DEMO"
      ManagedBy = "Terraform"
      Stack     = "rails"
    }
  }

  # Every service Floci supports, pinned to the emulator.
  #
  # A service NOT listed here goes to REAL AWS. Layer 2 (the placeholder
  # credentials below) means it would fail auth rather than touch anything, but
  # the error points at Amazon and reads as a mystery. So this list is generated:
  # `floci services` intersected with the AWS provider's valid endpoint keys.
  #
  # The Makefile also exports AWS_ENDPOINT_URL, which the provider honours for
  # ALL services at once (v5.31+). That covers the services Floci does not
  # implement too. This block is what protects you when you run terraform
  # directly, without make. See README § "How this stays off real AWS".
  endpoints {
    acm                      = var.floci_endpoint
    amp                      = var.floci_endpoint
    apigateway               = var.floci_endpoint
    apigatewayv2             = var.floci_endpoint
    appautoscaling           = var.floci_endpoint
    appconfig                = var.floci_endpoint
    appsync                  = var.floci_endpoint
    athena                   = var.floci_endpoint
    autoscaling              = var.floci_endpoint
    backup                   = var.floci_endpoint
    batch                    = var.floci_endpoint
    bcmdataexports           = var.floci_endpoint
    bedrock                  = var.floci_endpoint
    ce                       = var.floci_endpoint
    cloudcontrolapi          = var.floci_endpoint
    cloudformation           = var.floci_endpoint
    cloudfront               = var.floci_endpoint
    cloudhsmv2               = var.floci_endpoint
    cloudtrail               = var.floci_endpoint
    cloudwatch               = var.floci_endpoint
    cloudwatchlogs           = var.floci_endpoint
    codebuild                = var.floci_endpoint
    codedeploy               = var.floci_endpoint
    codegurureviewer         = var.floci_endpoint
    codepipeline             = var.floci_endpoint
    cognitoidp               = var.floci_endpoint
    comprehend               = var.floci_endpoint
    config                   = var.floci_endpoint
    connect                  = var.floci_endpoint
    controltower             = var.floci_endpoint
    cur                      = var.floci_endpoint
    docdb                    = var.floci_endpoint
    dynamodb                 = var.floci_endpoint
    ec2                      = var.floci_endpoint
    ecr                      = var.floci_endpoint
    ecs                      = var.floci_endpoint
    efs                      = var.floci_endpoint
    eks                      = var.floci_endpoint
    elasticache              = var.floci_endpoint
    elasticbeanstalk         = var.floci_endpoint
    elasticsearch            = var.floci_endpoint
    elb                      = var.floci_endpoint
    elbv2                    = var.floci_endpoint
    emr                      = var.floci_endpoint
    emrserverless            = var.floci_endpoint
    events                   = var.floci_endpoint
    firehose                 = var.floci_endpoint
    fis                      = var.floci_endpoint
    glue                     = var.floci_endpoint
    guardduty                = var.floci_endpoint
    iam                      = var.floci_endpoint
    identitystore            = var.floci_endpoint
    iot                      = var.floci_endpoint
    kafka                    = var.floci_endpoint
    kinesis                  = var.floci_endpoint
    kinesisanalytics         = var.floci_endpoint
    kinesisanalyticsv2       = var.floci_endpoint
    kms                      = var.floci_endpoint
    lakeformation            = var.floci_endpoint
    lambda                   = var.floci_endpoint
    lightsail                = var.floci_endpoint
    logs                     = var.floci_endpoint
    memorydb                 = var.floci_endpoint
    mq                       = var.floci_endpoint
    mwaa                     = var.floci_endpoint
    neptune                  = var.floci_endpoint
    networkfirewall          = var.floci_endpoint
    opensearch               = var.floci_endpoint
    organizations            = var.floci_endpoint
    pipes                    = var.floci_endpoint
    pricing                  = var.floci_endpoint
    ram                      = var.floci_endpoint
    rds                      = var.floci_endpoint
    redshift                 = var.floci_endpoint
    rekognition              = var.floci_endpoint
    resourceexplorer2        = var.floci_endpoint
    resourcegroupstaggingapi = var.floci_endpoint
    route53                  = var.floci_endpoint
    route53resolver          = var.floci_endpoint
    rum                      = var.floci_endpoint
    s3                       = var.floci_endpoint
    s3tables                 = var.floci_endpoint
    scheduler                = var.floci_endpoint
    secretsmanager           = var.floci_endpoint
    servicecatalog           = var.floci_endpoint
    servicediscovery         = var.floci_endpoint
    servicequotas            = var.floci_endpoint
    ses                      = var.floci_endpoint
    sesv2                    = var.floci_endpoint
    sfn                      = var.floci_endpoint
    sns                      = var.floci_endpoint
    sqs                      = var.floci_endpoint
    ssm                      = var.floci_endpoint
    ssoadmin                 = var.floci_endpoint
    sts                      = var.floci_endpoint
    swf                      = var.floci_endpoint
    transcribe               = var.floci_endpoint
    transfer                 = var.floci_endpoint
    wafv2                    = var.floci_endpoint
  }
}
