data "aws_caller_identity" "current" {}

data "aws_iam_roles" "all" {}

data "aws_iam_role" "project_roles" {
  for_each = toset([ for n in data.aws_iam_roles.all.names: n if contains(local.project_roles, n) ])
  name = each.value
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(flatten(values(var.vpc_configs)[*].subnet_ids))
  id = each.value
}


data "aws_iam_policy_document" "default" {

  statement {
    effect = "Allow"

    actions = [
      "codestar-connections:UseConnection",
    ]

    resources = ["arn:aws:codestar-connections:ap-southeast-1:${local.account_id}:connection/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = flatten([ for val in values(module.s3_buckets.buckets)[*].arn:[ val, "${val}/*"] ])
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "with_vpc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = distinct([ 
      for val in [ for arn in values(data.aws_subnet.selected)[*].arn: provider::aws::arn_parse(arn) ]:
      provider::aws::arn_build(val.partition, "ec2", val.region, val.account_id, "network-interface/*")
    ])

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"

      values = values(data.aws_subnet.selected)[*].arn
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = flatten([ for val in values(module.s3_buckets.buckets)[*].arn:[ val, "${val}/*"] ])
  }
}


data "aws_iam_policy_document" "codebuild_pipeline_buckets" {
  for_each = local.codepipeline_artifact_store_buckets
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [ 
        for v in each.value: "arn:aws:s3:::${v}/*"
     ]
  }
}
