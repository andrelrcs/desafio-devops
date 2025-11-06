variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "input_bucket_name" {
  description = "Custom name for the input bucket. If empty, a name will be generated"
  type        = string
  default     = ""
}

variable "output_bucket_name" {
  description = "Custom name for the output bucket. If empty, a name will be generated"
  type        = string
  default     = ""
}

variable "enable_versioning" {
  description = "Enable versioning for both input and output buckets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
