terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.84"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
        default-tag = "true"
    }
  }
}

locals {
  sources = {
    for k,v in var.sources: k=> merge(
    v,
    {
      buildspec = file("buildspec.yaml")
    })
    if k == "CodeBuildExampleProject"
  }
  roles = {
    for r_key,r_val in var.roles: r_key => merge(
      r_val,
      {
        policy = one([ for p_val in var.policies: jsonencode(p_val.policy) if r_key == p_val.role_key ])
      }
    )
  }
}

module "codebuild" {
  source = "../../"
    region = var.region
    buckets = var.buckets
    roles = local.roles
    projects = var.projects
    environments = var.environments
    environment_variables = var.environment_variables
    artifacts = var.artifacts
    sources = local.sources
    source_versions = var.source_versions
    build_batch_configs = var.build_batch_configs
    file_systems = var.file_systems
    vpc_configs = var.vpc_configs
    cache_configs = var.cache_configs
    tags = var.tags
}
