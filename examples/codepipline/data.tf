data "aws_iam_policy_document" "CodeBuildExampleProjectRolePolicy" {
  statement {
    sid = "ListAllMyBuckets"
    effect = "Allow"
    actions = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = [
      "arn:aws:s3:::*"
    ]
  }
}
