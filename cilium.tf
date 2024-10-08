# resource "null_resource" "delete_aws_cni" {
#   provisioner "local-exec" {
#     command = "curl -s -k -XDELETE -H 'Authorization: Bearer ${data.aws_eks_cluster_auth.cluster.token}' -H 'Accept: application/json' -H 'Content-Type: application/json' '${data.aws_eks_cluster.cluster.endpoint}/apis/apps/v1/namespaces/kube-system/daemonsets/aws-node'"
#   }
# }

resource "null_resource" "gateway_api_prerequisites" {
  for_each = toset(var.GATEWAT_API_PREREQUISITES)

  provisioner "local-exec" {
    command = each.key
  }
}

data "aws_iam_policy_document" "cilium" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:AssignPrivateIpAddresses",
      "ec2:CreateTags",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cilium" {
  name   = "${local.name}-cilium"
  policy = data.aws_iam_policy_document.cilium.json
}

module "irsa_ca" {
  source       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version      = "4.1.0"
  create_role  = true
  role_name    = "${local.name}-cilium"
  provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "/https?:///", "")
  role_policy_arns = [
    aws_iam_policy.cilium.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cilium-operator"]
}


resource "helm_release" "cilium" {
  name         = "cilium"
  namespace    = "kube-system"
  repository   = "https://helm.cilium.io/"
  chart        = "cilium"
  version      = "1.15.7"
  timeout      = 600
  force_update = false
  replace      = true
  values = [
    <<EOF
k8sServiceHost: ${replace(data.aws_eks_cluster.cluster.endpoint, "/https?:///", "")}
k8sServicePort: 443
kubeProxyReplacement: true
l7Proxy: true
cni:
  configMap: cni-configuration
  customConf: true
eni:
  enabled: true
  iamRole: "${module.irsa_ca.iam_role_arn}"
  updateEC2AdapterLimitViaAPI: true
  awsEnablePrefixDelegation: true
  awsReleaseExcessIPs: true
ipam:
  mode: eni
hubble:
  relay:
    enabled: true
  ui:
    enabled: true
tunnel: disabled
nodeinit:
  enabled: false
gatewayAPI:
  enabled: false
envoy:
  enabled: true
loadBalancer:
  l7:
    backend: envoy
EOF
  ]

  depends_on = [ 
    null_resource.gateway_api_prerequisites
  ]
}