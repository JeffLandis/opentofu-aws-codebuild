variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "pipeline" {
  type = object({
    region                                         = string
    codestar_connections                           = any
    codestar_connection_hosts                      = any
    host_vpc_configurations                        = any
    pipelines                                      = any
    artifact_store_buckets                         = any
    artifact_stores                                = any
    stages                                         = any
    stage_actions                                  = any
    triggers                                       = any
    trigger_git_configurations                     = any
    git_configuration_filters                      = any
    variables                                      = any
    codestarsourceconnection_action_configurations = any
    codebuild_action_configurations                = any
    tags                                           = map(string)
  })
}

variable "build" {
  type = object({
    region                       = string
    buckets                      = any
    roles                        = any
    projects                     = any
    environments                 = any
    environment_variables        = any
    artifacts                    = any
    sources                      = any
    source_versions              = any
    build_batch_configs          = any
    file_systems                 = any
    vpc_configs                  = any
    cache_configs                = any
    tags                         = map(string)
  })
}
