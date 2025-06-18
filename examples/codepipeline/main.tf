terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.80.0"
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
    for k,v in var.build.sources: k=> merge(
    v,
    {
      buildspec = file("buildspec-buildimage.yaml")
    })
    if k == "DockerImageBuildAndUpload"
  }
}

module "pipeline" {
  source = "github.com/JeffLandis/opentofu-aws-codepipeline?ref=v0.1.0-alpha"
    region                              = var.pipeline.region
    codestar_connections                = var.pipeline.codestar_connections
    codestar_connection_hosts           = var.pipeline.codestar_connection_hosts
    host_vpc_configurations             = var.pipeline.host_vpc_configurations
    pipelines                           = var.pipeline.pipelines
    artifact_store_buckets              = var.pipeline.artifact_store_buckets
    artifact_stores                     = var.pipeline.artifact_stores
    stages                              = var.pipeline.stages
    stage_actions                       = var.pipeline.stage_actions
    triggers                            = var.pipeline.triggers
    trigger_git_configurations          = var.pipeline.trigger_git_configurations
    git_configuration_filters           = var.pipeline.git_configuration_filters
    variables                           = var.pipeline.variables
    tags                                = var.pipeline.tags
    codestarsourceconnection_action_configurations = var.pipeline.codestarsourceconnection_action_configurations
    codebuild_action_configurations     = var.pipeline.codebuild_action_configurations
}

module "codebuild" {
  source = "../.."
    region = var.build.region
    buckets = var.build.buckets
    roles = var.build.roles
    codepipeline_artifact_stores = module.pipeline.artifact_stores_for_codebuild
    projects = var.build.projects
    environments = var.build.environments
    environment_variables = var.build.environment_variables
    artifacts = var.build.artifacts
    sources = local.sources
    source_versions = var.build.source_versions
    build_batch_configs = var.build.build_batch_configs
    file_systems = var.build.file_systems
    vpc_configs = var.build.vpc_configs
    cache_configs = var.build.cache_configs
    tags = var.build.tags
}
