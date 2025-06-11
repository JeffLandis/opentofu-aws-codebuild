locals {

  account_id = data.aws_caller_identity.current.account_id

  modules_repo = "github.com/JeffLandis"

  modules = {
    aws_s3 = {
      repo = "${local.modules_repo}/opentofu-aws-s3"
      version = "v0.1.0"
    }
  }

  buckets = [ for k,v in module.s3_buckets.buckets: merge(
      v,
      {
        key = one([ for val in var.buckets: val.key if coalesce(val.prefix, val.name) == k  ])
        prefix = one([ for val in var.buckets: val.prefix if val.prefix == k ])
      }
    )
  ]

  project_roles = distinct(concat(
    flatten([ for val in var.projects: compact([ val.service_role, val.resource_access_role ])]),
    compact([ for val in var.build_batch_configs: val.service_role ])
  ))

  role_arn_lookup_by_name = merge(
    { for k,v in data.aws_iam_role.project_roles: k => v.arn },
    { for k,v in aws_iam_role.this: k => v.arn }
  )

  projects = { for val in var.projects: val.name => merge(
      val,
      {
        service_role = try(regex("arn:aws.*:iam:.*", val.service_role), lookup(local.role_arn_lookup_by_name, val.service_role, null))
        environment = lookup(local.environments, val.environment_key, null)
        artifact = lookup(local.artifacts, val.artifact_key, null)
        source = lookup(var.sources, val.source_key, null)
        resource_access_role = val.resource_access_role == null ? null : try(regex("arn:aws.*:iam:.*", val.resource_access_role), lookup(local.role_arn_lookup_by_name, val.resource_access_role, null), null)
        build_batch_config = val.build_batch_config_key == null ? null : lookup(local.build_batch_configs, val.build_batch_config_key, null)
        file_system_locations = matchkeys(values(var.file_systems), keys(var.file_systems), val.file_system_keys)
        secondary_artifacts = matchkeys(values(local.artifacts), keys(local.artifacts), val.secondary_artifact_keys)
        secondary_sources = matchkeys(values(var.sources), keys(var.sources), val.secondary_source_keys)
        secondary_source_version = matchkeys(values(var.source_versions), keys(var.source_versions), val.secondary_source_version_keys)
        vpc_config = val.vpc_config_key == null ? [] : try([var.vpc_configs[val.vpc_config_key]], [])
        cache_config = val.cache_config_key == null ? [] : try([var.cache_configs[val.cache_config_key]], [])
      }
    )
  }

  artifacts = { for k,v in var.artifacts: k => merge(
      v,
      {
        location = (
          v.type != "S3" || v.bucket_key == null 
          ? null
          : one([ for val in local.buckets: val.name if val.key == v.bucket_key ])
        )
      }
    )
  }

  environments = { for k,v in var.environments: k => merge(
      v,
      {
        environment_variables = matchkeys(values(var.environment_variables), keys(var.environment_variables), v.environment_variable_keys)
        registry_credential = v.registry_credential_key == null ? [] : [lookup(var.registry_credentials, v.registry_credential_key, null)]
      } 
    )
  }

  build_batch_configs = { for k,v in var.build_batch_configs: k => merge(
      v, 
      {
        service_role = try(regex("arn:aws.*:iam:.*", v.service_role), lookup(local.role_arn_lookup_by_name, v.service_role, null), null)
      }
    )
  }

  artifact_store_buckets = distinct([ for val in var.codepipeline_artifact_stores: concat(val.artifact_store_buckets) ])
  
  codepipeline_artifact_store_buckets = { for k,v in {
      for val in var.codepipeline_artifact_stores: val.codebuild_project_name => val.artifact_store_buckets... 
    } : k => distinct(flatten(v))
  }

  attach_pipeline_policy_to_role = {
    for k_pol,v_pol in aws_iam_policy.codepipeline_artifact_stores: k_pol => merge(
      {
        policy_arn = v_pol.arn
      },
      {
        for k_proj,v_proj in local.projects: "role_name" => try(one(regex("arn:aws:iam::507845901198:role/(.*)", v_proj.service_role)), v_proj.service_role)
        if k_pol == v_proj.name
      })
  }

}