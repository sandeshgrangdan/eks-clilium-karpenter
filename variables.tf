##############################
### Extra variables
##############################
variable "AWS_REGION" {}
variable "AWS_ROLE_ARN" {}
variable "GATEWAT_API_PREREQUISITES" {}

# Launch Template
variable "vpc_id" {}
variable "instance_type" {
  type    = string
  default = "c5.large"
}
variable "max_size" {
  type = number
  default = 1
}
variable "min_size" {
  type    = number
  default = 1
}
variable "desired_capacity" {
  type    = number
  default = 1
}


