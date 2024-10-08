module "load_balancer_controller_irsa_role" {
  
  count = local.alb.create ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> v5.28.0"

  role_name                              = "aws-load-balancer-controller-${var.TF_ENVIRONMENT}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_issuer_arn
      namespace_service_accounts = ["kube-system:${local.alb.name}-sa"]
    }
  }

  tags = {
    Name           = "${local.alb.name}"
    ServiceAccount = "${local.alb.name}-sa"
  }
}

## create service accont and annotate with iam role
resource "kubernetes_service_account" "alb-serviceaccount" {
  metadata {
    name      = "${local.alb.name}-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa_role[0].iam_role_arn
    }
  }
  automount_service_account_token = true

  depends_on = [module.load_balancer_controller_irsa_role]
}

resource "helm_release" "alb-controller" {
  # for_each = toset(var.namespaces)

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.1"
  #version   = "1.5.2"
  #chart     = "https://aws.github.io/eks-charts/aws-load-balancer-controller-2.4.3.tgz"
  namespace = "kube-system"

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "${local.alb.name}-sa"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
    type  = "string"
  }

  set {
    name = "region"
    value = data.aws_region.current.name
  }

  set {
    name = "vpcId"
    value = var.vpc_id
  }

  # set {
  #   name  = "serviceMonitor.enabled"
  #   value = "true"
  # }

  depends_on = [kubernetes_service_account.alb-serviceaccount]
}

#####################################################
## enable access logs
####################################################
# resource "aws_s3_bucket" "elb_logs" {
#   count = local.alb.create ? 1 : 0

#   bucket        = "${var.TF_ENVIRONMENT}-alb-controller"
#   force_destroy = true
# }

# resource "aws_s3_bucket_acl" "policy" {
#   count  = local.alb.create ? 1 : 0
#   bucket = aws_s3_bucket.elb_logs[0].id
#   acl    = "private"
# }

# resource "aws_s3_bucket_ownership_controls" "ownership" {
#   count  = local.alb.create ? 1 : 0
#   bucket = aws_s3_bucket.elb_logs[0].id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

#resource "aws_s3_bucket_public_access_block" "private" {
#  count                   = local.alb.create ? 1 : 0
#  bucket                  = aws_s3_bucket.elb_logs[0].id
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

# resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
#   count  = local.alb.create ? 1 : 0
#   bucket = aws_s3_bucket.elb_logs[0].id
#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "${data.aws_elb_service_account.main.arn}"
#       },
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::${var.eks.cluster_name}/${var.TF_ENVIRONMENT}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
#     },
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "delivery.logs.amazonaws.com"
#       },
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::${var.eks.cluster_name}/${var.TF_ENVIRONMENT}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
#       "Condition": {
#         "StringEquals": {
#           "s3:x-amz-acl": "bucket-owner-full-control"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "delivery.logs.amazonaws.com"
#       },
#       "Action": "s3:GetBucketAcl",
#       "Resource": "arn:aws:s3:::${var.eks.cluster_name}"
#     }
#   ]
# }
# POLICY
# }

