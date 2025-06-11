#####################################################################
# REGION
#####################################################################
variable "region" {
  type = string
  description = "Default region"
}

#####################################################################
# S3 BUCKETS
#####################################################################
variable "buckets" {
  type = list(object({
    key = string
    name = optional(string, null)
    prefix = optional(string, null)
    force_destroy = optional(bool, true)
    tags = optional(map(string), {})
  }))
  default = []
  nullable = false
  validation {
    condition = alltrue([
      for v in var.buckets : anytrue([
        alltrue([ v.name != null, try(length(v.name), 0) > 0, try(length(v.name), 80) < 64 ]),
        alltrue([ v.prefix != null, try(length(v.prefix), 0) > 0, try(length(v.prefix), 80) < 38 ])
      ])
    ])
    error_message = <<-EOT
A valid bucket 'name' or 'prefix' is required, 'name' has precedence.
Must be lowercase, 'name' less than 64 characters and 'prefix' less than 38 characters.
EOT
  }
  description = <<-EOT
List of S3 buckets. At a minimum, 'name' **or** 'prefix' is required, 'name' has precedence.
This will create private buckets with the following configuration. An IAM policy will be added to the build projects role for access.
(versioning disabled, encrypted with aws/s3 KMS key, block all public access, bucket owner enforced, no bucket policy)
If you require a special configuration then you'll need to create the bucket separately and provide the bucket's name.

[Bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
| Attribute Name                         | Required?   | Default             | Description                                                                                                           |
|:---------------------------------------|:-----------:|:-------------------:|:----------------------------------------------------------------------------------------------------------------------|
| key                                    | required    |                     | Unique name to identify a bucket.                                                                                     |
| name                                   | conditional | null                | Name of the bucket, lowercase and less than 64 characters. Must specify name OR prefix.                               |
| prefix                                 | conditional | null                | Creates unique bucket name beginning with prefix, lowercase and less than 38 characters. Must specify name OR prefix. |
| force_destroy                          | optional    | true                | Whether all objects should be deleted when bucket is destroyed.                                                       |
| tags                                   | optional    | { }                 | A map of tags to assign to the bucket.                                                                                |      
EOT
}

#####################################################################
# IAM ROLES
#####################################################################
variable "roles" {
  type = map(object({
    name = optional(string, null)
    prefix = optional(string, null)
    description = optional(string, null)
    path = optional(string, null)
    max_session_duration = optional(number, 3600)
    permissions_boundary = optional(string, null)
    force_detach_policies = optional(bool, false)
    policy = optional(string, null)
    tags = optional(map(string), {})
  }))
  default = {}
  description = <<-EOT
Map (key/value pairs) of IAM roles that enables CodeBuild to interact with AWS services on behalf of the AWS account. The map's key must be unique to identify each role.
The map's key is used as `service_role` and `resource_access_role` in `projects` variable or `service_role` in `build_batch_configs` variable.
| Attribute Name        | Required?   | Default             | Description                                                                                                                                                   |
|:----------------------|:-----------:|:-------------------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                  | optional    | null                | Name of the role. Conflicts with `prefix`. If name and prefix are omitted, a random, unique name will be assigned.                                            |
| prefix                | optional    | null                | Creates a unique name beginning with the specified prefix. Conflicts with `name`. If name and prefix are omitted, a random, unique name will be assigned.     |
| description           | optional    | null                | Description of the role. Maximum length of 1000.                                                                                                              |      
| path                  | optional    | null                | Path to the role. For more information, see [IAM Identifiers](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html)                    |
| max_session_duration  | optional    | 3600                | Maximum session duration in seconds. (Minimum: 3600, Maximum: 43200) (1 to 12 hours)                                                                          |
| permissions_boundary  | optional    | null                | ARN of the managed policy that is used to set the permissions boundary for the role.                                                                          |
| force_detach_policies | optional    | false               | Whether to force detaching any policies the role has before destroying it. Defaults to false.                                                                 |      
| policy                | optional    | null                | The inline policy document as a JSON formatted string.                                                                                                        |
| tags                  | optional    | { }                 | A map of tags to assign to the role.                                                                                                                          |
EOT
}

#####################################################################
# CODEPIPELINE ARTIFACT STORES
#####################################################################
variable "codepipeline_artifact_stores" {
  type = list(object({
    codebuild_project_name = string
    artifact_store_buckets = list(string)
  }))
  default = [ ]
  description = "List of CodePipeline Artifact Stores"
}

#####################################################################
# CODEBUILD PROJECTS
#####################################################################
variable "projects" {
  type = list(object({
    name = string
    service_role = string
    environment_key = string
    artifact_key = string
    source_key = string
    source_version = optional(string, null)
    description = optional(string, null)
    badge_enabled = optional(bool, false)
    build_timeout = optional(number, 60)
    concurrent_build_limit = optional(number, null)
    encryption_key = optional(string, null)
    project_visibility = optional(string, "PRIVATE")
    resource_access_role = optional(string, null)
    queued_timeout = optional(number, 480)
    build_batch_config_key = optional(string, null)
    file_system_keys = optional(list(string), [])
    secondary_artifact_keys = optional(list(string), [])
    secondary_source_keys = optional(list(string), [])
    secondary_source_version_keys = optional(list(string), [])
    vpc_config_key = optional(string, null)
    cache_config_key = optional(string, null)
    cloudwatch_logs = optional(object({
      status = optional(string, "ENABLED")
      group_name = optional(string, null)
      stream_name = optional(string, null)
    }), {})
    s3_logs = optional(object({
      status = optional(string, "DISABLED")
      location = optional(string, null)
      bucket_owner_access = optional(string, null)
      encryption_disabled = optional(bool, null)
    }), {})

  }))
  default = []
  description = <<-EOT
Defines AWS CodeBuild projects.

[[Build projects](https://docs.aws.amazon.com/codebuild/latest/userguide/working-with-build-projects.html)]
[[AWS provider CodeBuild Project resource](https://search.opentofu.org/provider/opentofu/aws/latest/docs/resources/codebuild_project)]
| Attribute Name                          | Required?   | Default  | Description                                                                                                                                                                   |
|:----------------------------------------|:-----------:|:--------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                                    | required    |          | Name of the build project. Minimum length of 2. Maximum length of 150. [A-Za-z0-9][A-Za-z0-9\-_]{1,149}                                                                       |
| service_role                            | required    |          | A key from the `roles` variable or, name or ARN of a pre-existing/pre-defined IAM role that enables CodeBuild to interact with AWS services on behalf of the AWS account.     |                                                                  |
| environment_key                         | required    |          | Key from `environments` variable that identifies the project's environment.                                                                                                   |
| artifact_key                            | required    |          | Key from `artifacts` variable that identifies the project's artifacts.                                                                                                        |
| source_key                              | required    |          | Key from `sources` variable that identifies the project's source.                                                                                                             |
| source_version                          | optional    | null     | Version of the build input to be built. If not specified, latest version is used. [Sample](https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) |
| description                             | optional    | null     | Description that makes the build project easy to identify.                                                                                                                    |
| badge_enabled                           | optional    | false    | Set to true to generate a publicly accessible URL for your project's build badge.                                                                                             |      
| build_timeout                           | optional    | 60       | Minutes, from 5 to 2160 (36 hours), for CodeBuild to wait until timing out any build that does not get marked as completed.                                                   |
| concurrent_build_limit                  | optional    | null     | Maximum number of concurrent builds for the project. Set to a value greater than 0 to enable concurrent build limit.                                                          |
| encryption_key                          | optional    | null     | AWS Key Management Service (KMS) Customer Managed Key (CMK) used for encrypting build output artifacts. Specify either ARN or alias of the CMK.                               |
| project_visibility                      | optional    | PRIVATE  | Specifies the visibility of the project's builds. Valid Values: (PUBLIC_READ / PRIVATE)                                                                                       |
| resource_access_role                    | conditional | null     | If `project_visibility` is `PUBLIC_READ`, ARN of an IAM role that enables access to CloudWatch Logs and S3 artifacts for project's builds.                                    |
| queued_timeout                          | optional    | 480      | Number of minutes a build is allowed to be queued before it times out. (Minimum 5, Maximum 480, default: 480 (8 hours))                                                       |
| build_batch_config_key                  | optional    | null     | Key from `build_batch_configs` variable that defines the batch build options for the project.                                                                                 |
| file_system_keys                        | optional    | [ ]      | List of `file_system_keys` from `file_systems` variable, specifies file systems from EFS to mount in the build environment.                                                   |
| secondary_artifact_keys                 | optional    | [ ]      | List of map keys from the `artifacts` variable that identifies the project's secondary artifacts. (Minimum 0, Maximum 12)                                                       |
| secondary_source_keys                   | optional    | [ ]      | List of map keys from the `sources` variable that identifies the project's secondary sources. (Minimum 0, Maximum 12)                                                           |
| secondary_source_version_keys           | optional    | [ ]      | List of map keys from the `source_versions` variable that identifies the versions of project's secondary sources. (Minimum 0, Maximum 12)                                       |
| vpc_config_key                          | optional    | null     | Map key from `vpc_configs` variable that identifies the project's VPC configuration.                                                                                              |
| cache_config_key                        | optional    | null     | Key from `cache_configs` variable that defines the cache options for the project.                                                                                             |
| cloudwatch_logs                         | optional    | { }      | Information about CloudWatch Logs for a build project. CloudWatch Logs are enabled by default.                                                                                |
| <nobr>&ensp; status</nobr>              | optional    | ENABLED  | Current status of the logs in CloudWatch Logs for a build project. Valid Values: (ENABLED / DISABLED)                                                                         |
| <nobr>&ensp; group_name</nobr>          | optional    | null     | Group name of the logs in CloudWatch Logs.                                                                                                                                    |
| <nobr>&ensp; stream_name</nobr>         | optional    | null     | Prefix of the stream name of the CloudWatch Logs.                                                                                                                             |
| s3_logs                                 | optional    | { }      | Information about S3 Logs for a build project. S3 Logs are disabled by default.                                                                                               |
| <nobr>&ensp; status</nobr>              | optional    | DISABLED | Current status of the S3 build logs. Valid Values: (ENABLED / DISABLED)                                                                                                       |
| <nobr>&ensp; location</nobr>            | optional    | null     | Name of an S3 bucket and path prefix for logs. If S3 bucket name is 'my-bucket', and path prefix is 'build-log', then acceptable format is 'my-bucket/build-log'.             |
| <nobr>&ensp; bucket_owner_access</nobr> | optional    | null     | Bucket owner's access for objects that another account uploads to their Amazon S3 bucket. Valid Values: (NONE / READ_ONLY / FULL) Default is `NONE`.                          |
| <nobr>&ensp; encryption_disabled</nobr> | optional    | null     | Set to true if you do not want your S3 build log output encrypted. By default S3 build logs are encrypted.                                                                    |
EOT
}

#####################################################################
# CODEBUILD PROJECT ENVIRONMENTS
#####################################################################
variable "environments" {
  type = map(object({
    type = string
    compute_type = string
    image = string
    fleet_arn = optional(string, null)
    privileged_mode = optional(bool, false)
    certificate = optional(string, null)
    image_pull_credentials_type = optional(string, "CODEBUILD")
    environment_variable_keys = optional(list(string), [])
    registry_credential_key = optional(string, null)
  }))
  default = {}
  description = <<-EOT
Map of configurations that define the build environment of the build project. The map's key is used as `environment_key` in `projects` variable and must be unique to identify each environment. 

[[Project Environment Information](https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ProjectEnvironment.html)]
[[Build environment reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html)]
| Attribute Name              | Required | Default   | Description                                                                                                                                                                                                                                                                                                                    |
|:----------------------------|:--------:|:---------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| type                        | required |           | Type of build environment to use. Valid Values: (WINDOWS_CONTAINER / LINUX_CONTAINER / LINUX_GPU_CONTAINER / ARM_CONTAINER / WINDOWS_SERVER_2019_CONTAINER / LINUX_LAMBDA_CONTAINER / ARM_LAMBDA_CONTAINER / LINUX_EC2 / ARM_EC2 / WINDOWS_EC2 / MAC_ARM)                                                                      |   
| compute_type                | required |           | Information about compute resources the build project uses. Valid Values: (BUILD_GENERAL1_SMALL / BUILD_GENERAL1_MEDIUM / BUILD_GENERAL1_LARGE / BUILD_GENERAL1_XLARGE / BUILD_GENERAL1_2XLARGE / BUILD_LAMBDA_1GB / BUILD_LAMBDA_2GB / BUILD_LAMBDA_4GB / BUILD_LAMBDA_8GB / BUILD_LAMBDA_10GB / ATTRIBUTE_BASED_COMPUTE)     |
| image                       | required |           | Image identifier or digest that identifies the [Docker Image](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html) to use for this build project.                                                                                                                                              |
| fleet_arn                   | optional | null      | Compute fleet ARN for the build project.                                                                                                                                                                                                                                                                                       |
| privileged_mode             | optional | false     | Enables running the Docker daemon inside a Docker container. Set to true only if the build project is used to build Docker images.                                                                                                                                                                                             |
| certificate                 | optional | null      | ARN of S3 bucket, path prefix, and object key that contains the PEM-encoded certificate for the build project. For more information, see [certificate](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project.html#cli.environment.certificate) in the CodeBuild user guide.                                    |
| image_pull_credentials_type | optional | CODEBUILD | Type of credentials CodeBuild uses to pull images in your build. Valid Values: (CODEBUILD / SERVICE_ROLE)                                                                                                                                                                                                                      |
| environment_variable_keys   | optional | [ ]       | List of keys from `environment_variables` variable that identifies the project's environment variables.                                                                                                                                                                                                                        | 
| registry_credential_key     | optional | null      | Key from `registry_credentials` variable that identifies credentials for access to a private registry.                                                                                                                                                                                                                         |
EOT
}

#####################################################################
# CODEBUILD PROJECT ENVIRONMENT VARIABLES
#####################################################################
variable "environment_variables" {
  type = map(object({
    name = optional(string, null)
    type = optional(string, "PLAINTEXT")
    value = string
  }))
  default = {}
  description = <<-EOT
Map of environment variables to make available to builds. The map's key is used as `environment_variable_keys` in `environments` variable and must be unique to identify each variable. 
| Attribute Name | Required | Default   | Description                                                                                                                        |
|:---------------|:--------:|:---------:|:-----------------------------------------------------------------------------------------------------------------------------------|
| name           | optional | null      | Name of the environment variable. If not specified, `key` will be used.                                                            |   
| value          | required |           | Value of the environment variable. If type is `PARAMETER_STORE` or `SECRETS_MANAGER`, specify the name of the parameter or secret. |
| type           | optional | PLAINTEXT | Type of environment variable. Valid Values: (PLAINTEXT / PARAMETER_STORE / SECRETS_MANAGER)                                        |
EOT
}

#####################################################################
# CODEBUILD PROJECT ENVIRONMENT REGISTRY CREDENTIALS
#####################################################################
variable "registry_credentials" {
  type = map(object({
    credential = string
    credential_provider = optional(string, "SECRETS_MANAGER")
  }))
  default = {}
  description = <<-EOT
Map of credentials for access to a private registry. The map's key is used as `registry_credential_key` in `environments` variable and must be unique to identify each credential. 
| Attribute Name      | Required | Default         | Description                                                                                               |
|:--------------------|:--------:|:---------------:|:----------------------------------------------------------------------------------------------------------|
| credential          | required |                 | ARN or name of credentials created using AWS Secrets Manager.                                             |   
| credential_provider | optional | SECRETS_MANAGER | Service that created the credentials to access a private Docker registry. Valid Values: (SECRETS_MANAGER) |
EOT
}

#####################################################################
# CODEBUILD PROJECT ARTIFACTS
#####################################################################
variable "artifacts" {
  type = map(object({
    type = string
    artifact_identifier = optional(string, null)
    bucket_owner_access = optional(string, "NONE")
    encryption_disabled = optional(bool, false)
    override_artifact_name = optional(bool, false)
    bucket_key = optional(string, null)
    path = optional(string, null)
    namespace_type = optional(string, "NONE")
    name = optional(string, null)
    packaging = optional(string, "NONE")
  }))
  default = {}
  description = <<-EOT
Map of output artifacts for the build project. The map's key is used as `artifact_key` and `secondary_artifact_keys` in `projects` variable and must be unique to identify each artifact. 
| Attribute Name         | Required    | Default | Description                                                                                                                                                |
|:-----------------------|:-----------:|:-------:|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| type                   | required    |         | Type of build output artifact. Valid Values: (CODEPIPELINE / S3 / NO_ARTIFACTS)                                                                            |   
| artifact_identifier    | conditional | null    | Required for secondary artifacts. Artifact identifier, must be the same specified inside the AWS CodeBuild build specification.                            |
| bucket_owner_access    | optional    | NONE    | Specifies bucket owner's access for objects another account uploads. Valid Values: (NONE / READ_ONLY / FULL)                                               |
| encryption_disabled    | optional    | false   | If set to true, output artifacts are NOT encrypted.                                                                                                        |
| override_artifact_name | optional    | false   | If set to true, name specified in the buildspec file will override the artifact name.                                                                      |
| bucket_key             | optional    | null    | If `type` is `S3`, key from `buckets` variable identifies the output S3 bucket. Ignored for other types.                                                   |
| path                   | optional    | null    | If `type` is `S3`, path to the output artifact object. Ignored for other types. if not specified, path is not used.                                        |
| namespace_type         | optional    | NONE    | If `type` is `S3` and set to `BUILD_ID`, build ID included in path of the output artifact object. Valid Values: (NONE / BUILD_ID) Ignored for other types. |  
| name                   | optional    | null    | If `type` is `S3`, name of the output artifact object. Ignored for other types.                                                                            |
| packaging              | optional    | NONE    | Type of build output artifact to create. If set to ZIP, creates a zip file. Valid Values: (NONE / ZIP)                                                     |
EOT
}

#####################################################################
# CODEBUILD PROJECT SOURCES
#####################################################################
variable "sources" {
  type = map(object({
    type = string
    source_identifier = optional(string, null)
    buildspec = optional(string, null)
    location = optional(string, null)
    insecure_ssl = optional(string, null)
    git_clone_depth = optional(number, null)
    fetch_git_submodules = optional(bool, false)
    report_build_status = optional(bool, false)
    build_status_config = optional(object({
      context = optional(string, null)
      target_url = optional(string, null)
    }), null)
  }))
  default = {}
  description = <<-EOT
Map of input source code for the build project. The map's key is used as `source_key` and `secondary_source_keys` in `projects` variable and must be unique to identify each source. 
| Attribute Name        | Required    | Default | Description                                                                                                                                                                                           |
|:----------------------|:-----------:|:-------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| type                  | required    |         | Type of repository that contains source code. Valid Values: (CODECOMMIT / CODEPIPELINE / GITHUB / GITLAB / GITLAB_SELF_MANAGED / S3 / BITBUCKET / GITHUB_ENTERPRISE / NO_SOURCE)                      |   
| source_identifier     | conditional | null    | Required for secondary sources. Unique identifier for a source in the build project. Can only contain alphanumeric characters and underscores, and must be less than 128 characters in length.        |
| buildspec             | optional    | null    | The buildspec file declaration to use for the builds in this build project. Can be an inline buildspec definition, path to a buildspec file, or the path to an S3 bucket.                             |
| location              | optional    | NONE    | Information about the location of the source code from git or s3 to be built. [Location](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project.html#cli.source.location)]             |
| insecure_ssl          | optional    | null    | If `type` is `S3`, path to the output artifact object. Ignored for other types. if not specified, path is not used.                                                                                   |
| git_clone_depth       | optional    | null    | Information about the Git clone depth for the build project. Minimum value of 0.                                                                                                                      |  
| fetch_git_submodules  | optional    | false   | Set to true to fetch Git submodules for the AWS CodeBuild build project.                                                                                                                              |
| report_build_status   | optional    | null    | If `type` is `S3`, name of the output S3 bucket. Ignored for other types.                                                                                                                             |  
| build_status_config   | optional    | false   | Defines how the project reports the build status to the source provider. [BuildStatusConfig](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project.html#cli.source.buildstatusconfig) |
| &ensp; context        | optional    | null    | Specifies the context of the build status CodeBuild sends to the source provider.                                                                                                                     |
| &ensp; target_url     | optional    | null    | Specifies the target url of the build status CodeBuild sends to the source provider.                                                                                                                  |
EOT
}

#####################################################################
# CODEBUILD PROJECT SOURCE VERSIONS
#####################################################################
variable "source_versions" {
  type = map(object({
    source_identifier = string
    source_version = string
  }))
  default = {}
  description = <<-EOT
Map of source identifiers and its corresponding version for the build project. The map's key is used as `secondary_source_version_keys` in `projects` variable and must be unique to identify each source version. 
| Attribute Name    | Required | Default | Description                                                                                                                                                                   |
|:------------------|:--------:|:-------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| source_identifier | required |         | Unique identifier for a source in the build project. Can only contain alphanumeric characters and underscores, and must be less than 128 characters in length.                |   
| source_version    | required |         | Version of the build input to be built. If not specified, latest version is used. [Sample](https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) |
EOT
}

#####################################################################
# CODEBUILD PROJECT BUILD BATCH CONFIGS
#####################################################################
variable "build_batch_configs" {
  type = map(object({
    service_role = string
    combine_artifacts  = optional(bool, false)
    timeout_in_mins = optional(number, 480)
    restrictions = optional(object({
      compute_types_allowed =  optional(list(string), null)
      maximum_builds_allowed = optional(number, null)
    }), null)
  }))
  default = {}
  description = <<-EOT
Map of configurations that define the batch build options for the project. The map's key is used as `build_batch_config_key` in `projects` variable and must be unique to identify each file system. 
Contains configuration information about a batch build project.
| Attribute Name                | Required | Default   | Description                                                                                                                                                                     |
|:------|:--------:|:----------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| service_role                  | required |           | Specifies the service role ARN for the batch build project.                                                                                                                     |   
| combine_artifacts             | optional | false     | Specifies if the build artifacts for the batch build should be combined into a single artifact location.                                                                        |
| timeout_in_mins               | optional | 480       | Maximum amount of time, in minutes, that batch build must be completed in. (Minimum 5, Maximum 2160, default: 480 (8 hours))                                                    |
| restrictions                  | optional | null      |  Specifies the restrictions for the batch build.                                                                                                                                |
| &ensp; compute_types_allowed  | optional | null      | List of strings that specify the [compute types](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html) that are allowed for the batch build. |
| &ensp; maximum_builds_allowed | optional | null      | Specifies the maximum number of builds allowed. If a batch exceeds this limit, the batch will fail. (Minimum 1, Maximum 100)                                                    |
EOT
}

#####################################################################
# CODEBUILD PROJECT FILE SYSTEMS
#####################################################################
variable "file_systems" {
  type = map(object({
    identifier = optional(string, null)
    location = optional(string, null)
    mount_point = optional(string, null)
    mount_options = optional(string, null)
    type = optional(string, "EFS")
  }))
  default = {}
  description = <<-EOT
Map of file systems from EFS to mount into the build environment. The map's key is used as `file_system_keys` in `projects` variable and must be unique to identify each file system. 
| Attribute Name | Required | Default | Description                                                                                                                                                                                                                                                       |
|:---------------|:--------:|:-------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| identifier     | optional | null    | Name used to access an EFS, identifier is used to mount the file system. An environment variable is created by appending the identifier, in upper case, to 'CODEBUILD_'. For example, for the identifier 'my_efs', a  variable is created named CODEBUILD_MY_EFS. |   
| mount_point    | optional | null    | Location in the container where you mount the file system.                                                                                                                                                                                                        |
| mount_options  | optional | null    | Mount options for a file system created by EFS. Default options are 'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2'.                                                                                                                           |   
| type           | optional | EFS     | Type of file system, only type supported is `EFS`.                                                                                                                                                                                                                |
EOT
}

#####################################################################
# CODEBUILD PROJECT VPC CONFIGS
#####################################################################
variable "vpc_configs" {
  type = map(object({
    vpc_id = string
    subnet_ids = list(string)
    security_group_ids = list(string)
  }))
  default = {}
  description = <<-EOT
Map of VPC configurations to enable CodeBuild to access resources in a VPC. The map's key is used as `vpc_config_key` in `projects` variable and must be unique to identify each VPC config. 
Enables CodeBuild to access resources in an Amazon VPC.
| Attribute Name     | Required | Default | Description                                                                            |
|:-------------------|:--------:|:-------:|:---------------------------------------------------------------------------------------|
| vpc_id             | required |         | ID of the VPC to use for project's build resources.                                    |
| subnet_ids         | required |         | List of one or more subnet IDs in the VPC.                                             |   
| security_group_ids | required |         | List of one or more security group IDs in the VPC.                                     |
EOT
}

#####################################################################
# CODEBUILD PROJECT VPC CONFIGS
#####################################################################
variable "cache_configs" {
  type = map(object({
    type = string
    location = optional(string, null)
    modes = optional(list(string), null)
  }))
  default = {}
  description = <<-EOT
Map of cache configurations for the build project. The map's key is used as `cache_config_key` in `projects` variable and must be unique to identify each cache config. 
| Attribute Name | Required    | Default  | Description                                                                                                                                                     |
|:---------------|:-----------:|:--------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| type           | optional    | NO_CACHE | Type of cache used by the build project. Valid Values: (NO_CACHE / S3 / LOCAL)                                                                                  |
| location       | conditional | null     | Required when cache `type` is `S3`, S3 bucket name and prefix.                                                                                                  |   
| modes          | conditional | null     | Required when cache `type` is `LOCAL`, list of one or more local cache modes. Valid Values:(LOCAL_SOURCE_CACHE / LOCAL_DOCKER_LAYER_CACHE / LOCAL_CUSTOM_CACHE) |
EOT
}

######################################################
# TAGS
######################################################
variable "tags" {
  type = map(string)
  nullable = false
  default = {}
  description = "Map of tags to assign to all resources in module"
}
