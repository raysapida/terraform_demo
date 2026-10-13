#!/usr/bin/env bash
# Probes what this build of Floci actually supports.
# Run this before the talk. Results move; docs/FINDINGS.md is a snapshot.
set -uo pipefail
cd "$(dirname "$0")/.."
AWS="./scripts/awslocal"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

pass=0; fail=0
check() { # check <label> <command...>
  local label="$1"; shift
  if out=$("$@" 2>&1); then
    printf '  \033[32m✓\033[0m %s\n' "$label"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m %s\n      %s\n' "$label" "$(echo "$out" | grep -oE '\(.*\) when calling|UnsupportedOperation|not supported' | head -1)"
    fail=$((fail+1))
  fi
}

echo "Floci version:"
docker logs playful-programming-floci 2>&1 | grep -oE 'AWS Local Emulator [0-9.]+' | head -1 | sed 's/^/  /'
echo
echo "Core networking (the demo needs all of these):"
VPC=$($AWS ec2 create-vpc --cidr-block 10.99.0.0/16 --query Vpc.VpcId --output text 2>/dev/null)
check "CreateVpc"                 test -n "$VPC"
check "CreateTags"                $AWS ec2 create-tags --resources "$VPC" --tags Key=Name,Value=verify-probe
check "DescribeVpcs w/ tag filter" $AWS ec2 describe-vpcs --filters Name=tag:Name,Values=verify-probe
check "CreateSubnet"              $AWS ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.99.1.0/24
check "CreateSecurityGroup"       $AWS ec2 create-security-group --vpc-id "$VPC" --group-name verify-probe --description probe

echo
echo "VPC peering (Act III's literal subject — expected to FAIL on 2.0.1):"
check "CreateVpcPeeringConnection"    $AWS ec2 create-vpc-peering-connection --vpc-id "$VPC" --peer-vpc-id "$VPC"
check "DescribeVpcPeeringConnections" $AWS ec2 describe-vpc-peering-connections

echo
echo "Other services:"
check "RDS  DescribeDBInstances"  $AWS rds describe-db-instances
check "IAM  ListUsers"            $AWS iam list-users
check "S3   ListBuckets"          $AWS s3api list-buckets
check "ECR  DescribeRepositories" $AWS ecr describe-repositories

$AWS ec2 delete-vpc --vpc-id "$VPC" >/dev/null 2>&1 || true
echo
echo "  $pass passed, $fail failed"
echo "  Peering failures are expected and the demo is designed around them."
echo "  Anything else failing means docs/FINDINGS.md is stale — update it."
