locals {
  name = "mst-devops-eks"
  name_prefix = "mst-devops-sharedinfra-eks"

  config = {
    Product     = "mst"
    Environment = "production"
    Service     = "devops-eks"
    Team        = "MST DevOps"
    Management  = "terraform"
    Name        = local.name
  }

  max_size      =  var.max_size
  instance_type =  var.instance_type

  oidc_issuer   = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "/https?:///", "")
  account_id    = data.aws_caller_identity.current.account_id

  oidc_issuer_arn = "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_issuer}"
}

# UserData
locals {
    user_data = <<-EOT
[settings.kubernetes]
"cluster-name" = "${local.name_prefix}"
"api-server" = "${data.aws_eks_cluster.cluster.endpoint}"
"cluster-certificate" = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1UQXlNREV4TXpjd01Wb1hEVE14TVRBeE9ERXhNemN3TVZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTjU1CjdpQVVONTFtaHo1Z1FkL2xEZ3l4VVRJK1JJampXUnNQNnlLTytJMTVEUzYySWlDK0x6Ly9IaTJ6ek81NDdFQkYKaDJkcFVLYkRZYldqYUxsSnNKSVRsdWYvb05URFZaakdvckxNOFZUeWgxd3ZKNnc5dEY0R0ZSK1NmbGQxQlJ2NQpCVzBnLzB3NFJMQmhvcHI1SHltRDNJaFZUTUx2Y0NOOGhNejZUbm5kMjNoQTkrMHNYQUdCdGdVa3pMRTRkaytLCkg2Q3pPRGh0WUNnTkNoVHpRL0o5akVkZDJOYTJPSGtONmVjd1lLTkNJY20zOE5JRVl0RlEwVURjSlhQSFg0cWYKVnhucG9YMGd1RlRXTUl6eVpGeUZxT2hvT3ZOTEhhcVZtQU9zVG93cGl5NkVMU29mNThrWjAvN1ZaR2tBd3dMUgpYUG8ybTJKdDk4VkMxb3Z1SGUwQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZLaFhDMkVhT3JHSWRVb1JFaWY3eFUzUXpWNGVNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBc0VxZkFxVzRlTHFCZWVNUlhKKytXVnFhNnYvSEg1U0FsaVRMaHpXZjZIbDdXWlY1aworMXd3MDBtR2M5RG9FTW1IRjdhZkE3WUhMQyt6cVNrZHFkM081VGx0OVExSlZaeWhBU24wZkxtSkF2Y3ZaTVowCjJoRVdUcHAwc0FYNVVnbVVRejluMGZnejJnNUI0VG0rL0U4RUViWDA4VGxDV3FJaFNiMVl4aXNWUFZLeUYwdG0KNGJiMjlUS2JaR3ZnQldKL1dwMTl2K3lpa0c3eGJrMGNoTGo1T3J2WDltVmFZZk5LUHFESERlTmFmekkwOTh4MwpVamhEWVc3RnIxeVFuSFd3SEN5MXloUitlMTh6RGZkWUk0N01GMU1NVDlYVWhjWGhIQS9BUXRUc1luYkZLdlZTCnZKdVluek5qQTV2YjYvbjRVZTJaUkgzWkJ1L1h4cGNlNitqWAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
"cluster-dns-ip" = "10.100.0.10"
"max-pods" = 110
[settings.kubernetes.node-labels]
"instance_mode" = "ondemand"
"eks.amazonaws.com/nodegroup-image" = "ami-0bd5c4d95f68d5f48"
"eks.amazonaws.com/capacityType" = "ON_DEMAND"
"eks.amazonaws.com/nodegroup" = "mst-devops-eks"
"service_mode" = "ondemand"
[settings.kubernetes.node-taints]
"node.cilium.io/agent-not-ready" = "true:NoExecute"
dedicated = "experimental:PreferNoSchedule"
special = "true:PreferNoSchedule"
[settings.host-containers.admin]
enabled = false
[settings.kernel]
lockdown = "integrity"
[settings.kubernetes.node-labels]
"environment" = "production"
EOT
}
