variable "TF_ENVIRONMENT" {}
variable "cluster_name" {}
variable "vpc_id" {}

variable "oidc_issuer_arn" {
  type = string
  default = ""
}
