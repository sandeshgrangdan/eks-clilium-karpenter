
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = local.name_prefix

  create_node_iam_role = false
  node_iam_role_arn    = module.eks_managed_node_group.iam_role_arn
  create_access_entry = false
  # EKS Fargate currently does not support Pod Identity
  enable_irsa            = true
  irsa_oidc_provider_arn = local.oidc_issuer_arn

  # Used to attach additional IAM policies to the Karpenter node IAM role
  # node_iam_role_additional_policies = {
  #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  # }

  depends_on = [ module.eks_managed_node_group ]
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.35.1"
  wait                = false

  values = [
    <<-EOT
    settings:
      clusterName: ${local.name_prefix}
      interruptionQueue: ${module.karpenter.queue_name}
    controller:
      resources:
        cpu: 1
        memory: 1Gi
      limit:
        cpu: 1
        memory: 1Gi
    EOT
  ]

  depends_on = [
    module.karpenter
  ]
}


# resource "kubectl_manifest" "karpenter_node_class" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1beta1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiFamily: AL2
#       role: ${module.eks_managed_node_group.iam_role_arn}
#       subnetSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${local.name_prefix}
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${local.name_prefix}
#       amiSelectorTerms:
#         - id: ami-0d4f6257f835ecb0d
#         - id: ami-02e34459acfa72945
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_pool" {
#   yaml_body = <<-YAML
#   apiVersion: karpenter.sh/v1beta1
#   kind: NodePool
#   metadata:
#     name: default
#   spec:
#     template:
#       spec:
#         requirements:
#           - key: kubernetes.io/arch
#             operator: In
#             values: ["amd64"]
#           - key: kubernetes.io/os
#             operator: In
#             values: ["linux"]
#           - key: karpenter.sh/capacity-type
#             operator: In
#             values: ["spot"]
#           - key: karpenter.k8s.aws/instance-category
#             operator: In
#             values: ["c", "m", "r"]
#           - key: karpenter.k8s.aws/instance-generation
#             operator: Gt
#             values: ["2"]
#         nodeClassRef:
#           apiVersion: karpenter.k8s.aws/v1beta1
#           kind: EC2NodeClass
#           name: default
#     limits:
#       cpu: 1000
#     disruption:
#       consolidationPolicy: WhenUnderutilized
#       expireAfter: 720h # 30 * 24h = 720h
#   YAML

#   depends_on = [
#     kubectl_manifest.karpenter_node_class
#   ]
# }

# resource "kubectl_manifest" "karpenter_example_deployment" {
#   yaml_body = <<-YAML
#     apiVersion: apps/v1
#     kind: Deployment
#     metadata:
#       name: inflate
#       namespace: development
#     spec:
#       replicas: 2
#       selector:
#         matchLabels:
#           app: inflate
#       template:
#         metadata:
#           labels:
#             app: inflate
#         spec:
#           terminationGracePeriodSeconds: 0
#           containers:
#             - name: inflate
#               image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
#               resources:
#                 requests:
#                   cpu: 1
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }