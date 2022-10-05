variable "entry_point" {}
variable "function_name" {}
variable "function_description" {}
variable "function_source_path" {}
variable "bucket_name" {}
variable "environment_variables" {}
variable "secret_environment_variables" {
  default = []
}
variable "event_trigger" {
  default = []
}
