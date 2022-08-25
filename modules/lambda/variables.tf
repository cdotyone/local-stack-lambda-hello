variable "name" {
  type        = string
  description = "name of the lambda function"
}

variable "tags" {
  type        = map(string)
  description = "base set of tags to add to resources"
  default     = {}
}

variable "environment" {
  type        = map(string)
  description = "map containing environment variables to add to lambda"
  default     = {}
}