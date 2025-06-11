output "buckets" {
  value = local.buckets
}

output "projects" {
  value = aws_codebuild_project.this
}

output "codepipeline_artifact_stores" {
  value = local.codepipeline_artifact_store_buckets
}

# output "buckets" {
#   value = flatten([ for val in values(module.s3_buckets.buckets)[*].arn:
#     [ val, "${val}/*"]
#   ])
# }

# output "aws_subnet" {
#   #value = data.aws_subnet.selected
#   value = toset(flatten(values(var.vpc_configs)[*].subnet_ids))
# }attach_pipeline_policy_to_role

output "attach_pipeline_policy_to_role" {
  value = local.attach_pipeline_policy_to_role
}

output "aws_iam_policy_document" {
  value = data.aws_iam_policy_document.codebuild_pipeline_buckets
}

# output "aws_subnet" {
#   value = distinct([ 
#     for val in [ for arn in values(data.aws_subnet.selected)[*].arn: provider::aws::arn_parse(arn) ]:
#     provider::aws::arn_build(val.partition, "ec2", val.region, val.account_id, "network-interface/*")
#   ])
# }

# output "role_arn_lookup_by_name" {
#   value = local.role_arn_lookup_by_name
# }

# output "data_all_roles" {
#   value = data.aws_iam_roles.all
# }

# output "project_roles" {
#   value = local.project_roles
# }

# output "roles" {
#   value = aws_iam_role.this
# }

# output "projects" {
#   value = local.projects
# }

# output "environments" {
#   value = local.environments
# }

# output "environment_variables" {
#   value = local.environment_variables
# }

# output "artifacts" {
#   value = local.artifacts
# }

# output "sources" {
#   value = var.sources
# }

# output "tags" {
#   value = var.tags
# }
