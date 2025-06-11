#####################################################################
# MODULE S3_BUCKETS
#####################################################################
module "s3_buckets" {
  # source = "${local.modules.aws_s3.repo}?ref=${local.modules.aws_s3.version}"
  source = "github.com/JeffLandis/opentofu-aws-s3?ref=v0.2.0"
  buckets = var.buckets
}

#####################################################################
# RESOURCE AWS_IAM_ROLE
#####################################################################
resource "aws_iam_role" "this" {
  for_each = var.roles
  name = each.value.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#####################################################################
# RESOURCE AWS_IAM_ROLE_POLICY
#####################################################################
resource "aws_iam_role_policy" "this" {
  for_each = { 
    for k,v in var.roles: k => v.policy
    if v.policy != null  
  }
  name = "${aws_iam_role.this[each.key].name}InlinePolicy"
  role = aws_iam_role.this[each.key].id
  policy = each.value
}

#####################################################################
# RESOURCE AWS_IAM_POLICY
#####################################################################
resource "aws_iam_policy" "this" {
  for_each = aws_iam_role.this
  name        = "${each.value.name}Policy"
  description = "Policy for CodeBuild project ${each.value.name} to call AWS services on your behalf."
  policy      = data.aws_iam_policy_document.default.json
  tags = merge({Name = "${each.value.name}Policy"}, var.tags)
}

resource "aws_iam_policy" "codepipeline_artifact_stores" {
  for_each = data.aws_iam_policy_document.codebuild_pipeline_buckets
  name        = "CodeBuild.${each.key}CodePipelineAccessPolicy"
  description = "Policy for CodeBuild project ${each.key} to access CodePipeline Artifact Stores."
  policy      = each.value.json
  tags = merge({Name = "${each.key}Policy"}, var.tags)
}

#####################################################################
# RESOURCE AWS_IAM_ROLE_POLICY_ATTACHMENT
#####################################################################
resource "aws_iam_role_policy_attachment" "this" {
   for_each = aws_iam_role.this
  role       = each.value.name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_iam_role_policy_attachment" "codepipeline_artifact_stores" {
  for_each = local.attach_pipeline_policy_to_role
  role       = each.value.role_name
  policy_arn = each.value.policy_arn
}

#####################################################################
# RESOURCE AWS_CODEBUILD_PROJECT
#####################################################################
resource "aws_codebuild_project" "this" {
  for_each = local.projects
  name           = each.value.name
  service_role = each.value.service_role
  description    = each.value.description
  build_timeout  = each.value.build_timeout
  queued_timeout = each.value.queued_timeout
  badge_enabled = each.value.badge_enabled
  concurrent_build_limit = each.value.concurrent_build_limit
  encryption_key = each.value.encryption_key
  project_visibility = each.value.project_visibility
  resource_access_role = each.value.resource_access_role
  source_version = each.value.source_version

  ###############
  # ENVIRONMENT #
  ###############
  environment {
    type = each.value.environment.type
    compute_type = each.value.environment.compute_type
    image = each.value.environment.image
    privileged_mode = each.value.environment.privileged_mode
    certificate = each.value.environment.certificate
    image_pull_credentials_type = each.value.environment.image_pull_credentials_type

    dynamic "environment_variable" {
      for_each = each.value.environment.environment_variables
      content {
        name = environment_variable.value.name
        type = environment_variable.value.type
        value = environment_variable.value.value
      }
    }

    dynamic "fleet" {
      for_each = each.value.environment.fleet_arn == null ? [] : toset([ each.value.environment.fleet_arn ])
      content {
        fleet_arn = fleet.value
      }
    }

    dynamic "registry_credential" {
      for_each = each.value.environment.registry_credential
      content {
        credential = registry_credential.value.credential
        credential_provider = registry_credential.value.credential_provider
      }
    }

  }

  ##########
  # SOURCE #
  ##########
  source {
    type = each.value.source.type
    buildspec = each.value.source.buildspec
    location = each.value.source.location
    insecure_ssl = each.value.source.insecure_ssl
    git_clone_depth = each.value.source.git_clone_depth
    report_build_status = each.value.source.report_build_status

    dynamic "git_submodules_config" {
      for_each = (
        each.value.source.fetch_git_submodules &&
        contains(["CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED"], each.value.source.type)
        ? [1]
        : []
      )
      content {
        fetch_submodules = true
      }
    }

    dynamic "build_status_config" {
      for_each = each.value.source.build_status_config == null ? [] : [ each.value.source.build_status_config ]
      content {
        context = build_status_config.value.context
        target_url = build_status_config.value.target_url
      }
    }
  }

  #############
  # ARTIFACTS #
  #############
  artifacts {
    type = each.value.artifact.type
    artifact_identifier = each.value.artifact.artifact_identifier
    bucket_owner_access = each.value.artifact.bucket_owner_access
    encryption_disabled = each.value.artifact.encryption_disabled
    override_artifact_name = each.value.artifact.override_artifact_name
    location = each.value.artifact.location
    path = each.value.artifact.path
    namespace_type = each.value.artifact.namespace_type
    name = each.value.artifact.name
    packaging = each.value.artifact.packaging
  }

  #########################
  # FILE_SYSTEM_LOCATIONS #
  #########################
  dynamic "file_system_locations" {
    for_each = each.value.file_system_locations
    content {
      identifier = file_system_locations.value.identifier
      location = file_system_locations.value.location
      mount_point = file_system_locations.value.mount_point
      mount_options = file_system_locations.value.mount_options
      type = file_system_locations.value.type
    }
  }

  #####################
  # SECONDARY_SOURCES #
  #####################
  dynamic "secondary_sources" {
   for_each = each.value.secondary_sources
    content {
      type = secondary_sources.value.type
      source_identifier = secondary_sources.value.source_identifier
      buildspec = secondary_sources.value.buildspec
      location = secondary_sources.value.location
      insecure_ssl = secondary_sources.value.insecure_ssl
      git_clone_depth = secondary_sources.value.git_clone_depth
      report_build_status = secondary_sources.value.report_build_status

      dynamic "git_submodules_config" {
        for_each = (
          secondary_sources.value.fetch_git_submodules &&
          contains(["CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED"], each.value.source.type)
          ? [1]
          : []
        )
        content {
          fetch_submodules = true
        }
      }

      dynamic "build_status_config" {
        for_each = secondary_sources.value.build_status_config == null ? [] : [ each.value.source.build_status_config ]
        content {
          context = build_status_config.value.context
          target_url = build_status_config.value.target_url
        }
      }
    }
  }

  ############################
  # SECONDARY_SOURCE_VERSION #
  ############################
  dynamic "secondary_source_version" {
    for_each = each.value.secondary_source_version
    content {
      source_identifier = secondary_source_version.value.source_identifier
      source_version = secondary_source_version.value.source_version
    }
  }

  #######################
  # SECONDARY_ARTIFACTS #
  #######################
  dynamic "secondary_artifacts" {
    for_each = each.value.secondary_artifacts
    content {
      type = secondary_artifacts.value.type
      artifact_identifier = secondary_artifacts.value.artifact_identifier
      bucket_owner_access = secondary_artifacts.value.bucket_owner_access
      encryption_disabled = secondary_artifacts.value.encryption_disabled
      override_artifact_name = secondary_artifacts.value.override_artifact_name
      location = secondary_artifacts.value.location
      path = secondary_artifacts.value.path
      namespace_type = secondary_artifacts.value.namespace_type
      name = secondary_artifacts.value.name
      packaging = secondary_artifacts.value.packaging
    }
  }

  #########
  # CACHE #
  #########
  dynamic "cache" {
    for_each = each.value.cache_config
    content {
      type = cache.value.type
      location = cache.value.location
      modes = cache.value.modes
    }
  }

  ##############
  # VPC_CONFIG #
  ##############
  dynamic "vpc_config" {
    for_each = each.value.vpc_config
    content {
      vpc_id = vpc_config.value.vpc_id
      subnets = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  ###############
  # LOGS_CONFIG #
  ###############
  logs_config {
    cloudwatch_logs {
      status = try(each.value.cloudwatch_logs.status, "ENABLED")
      group_name = try(each.value.cloudwatch_logs.group_name, null)
      stream_name = try(each.value.cloudwatch_logs.stream_name, null)
    }
    s3_logs {
      status = try(each.value.s3_logs.status, "DISABLED")
      location = try(each.value.s3_logs.location, null)
      bucket_owner_access = try(each.value.s3_logs.bucket_owner_access, null)
      encryption_disabled = try(each.value.s3_logs.encryption_disabled, null)
    }
  }

  ########
  # TAGS #
  ########
  tags = {
    Environment = "Test"
  }

}
