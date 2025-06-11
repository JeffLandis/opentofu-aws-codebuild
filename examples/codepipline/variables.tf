variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "buckets" {
  type = any
  default = []
}

variable "roles" {
  type = any
  default = {}
}

variable "policies" {
  type = any
  default = []
}

variable "projects" {
  type = any
  default = []
}

variable "environments" {
  type = any
  default = {}
}

variable "environment_variables" {
  type = any
  default = {}
}

variable "registry_credentials" {
  type = any
  default = {}
}

variable "artifacts" {
  type = any
  default = {}
}

variable "sources" {
  type = any
  default = {}
}

variable "source_versions" {
  type = any
  default = {}
}

variable "build_batch_configs" {
  type = any
  default = {}
}

variable "file_systems" {
  type = any
  default = {}
}

variable "vpc_configs" {
  default = {}
  type = any
}

variable "cache_configs" {
  type = any
  default = {}
}

variable "tags" {
  type = map(string)
  default = {}
}
