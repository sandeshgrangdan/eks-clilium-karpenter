module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = local.name
  create_private_key = true
}

module "ebs_kms" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.0"
  description = "KMS key for EBS Volume"

  # Aliases
  aliases                 = ["ebs/kms-key"]
  aliases_use_name_prefix = true

  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  #key_service_users = [
  #  # required for the ASG to manage encrypted volumes for nodes
  #  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
  #  # required for the cluster / persistentvolume-controller to create encrypted PVCs
  #  module.eks.cluster_iam_role_arn,
  #]

  #key_statements = data.aws_iam_policy_document.ebs_key_policy.statement

  tags = {
    Component = "ebs"
    Name      = "ebs-kms-key"
  }
}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "mst-devops"
  cluster_name    = local.name_prefix
  cluster_version = "1.29"

  use_name_prefix       = true

  subnet_ids = ["subnet-0729de56e2446f174","subnet-07a8187e714f33c16"]

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = "sg-034ee1b2843f96d42"
  vpc_security_group_ids            = ["sg-0273fd24aca759c4c","sg-038bea8ff227216db","sg-077c85e7acb90ecba"]

  iam_role_attach_cni_policy = true
  use_custom_launch_template = false

  min_size     = 1
  max_size     = 1
  desired_size = 1

  ami_type                   = "BOTTLEROCKET_x86_64"
  platform                   = "bottlerocket"
    enable_bootstrap_user_data = true
    bootstrap_extra_args       = <<-EOT
      [settings.host-containers.admin]
      enabled = false
      [settings.kernel]
      lockdown = "integrity"
      [settings.kubernetes.node-labels]
      "environment" = "production"
      [settings.kubernetes.node-taints]
      dedicated = "experimental:PreferNoSchedule"
      special = "true:PreferNoSchedule"
    EOT

    force_update_version = true
    disk_size            = 30
    instance_types = ["c5.large"]
    capacity_type  = "SPOT"

      labels = {
        instance_mode = "spot"
        service_mode  = "spot"
      }

      taints = [
        {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      ]

      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }



      disable_api_termination = false
      ebs_optimized           = true
      enable_monitoring       = true

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        encrypted             = true
        kms_key_id            = module.ebs_kms.key_arn
        delete_on_termination = true
      }
    }
  ]

  metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

  tags = {
    "k8s.io/cluster-autoscaler/mst-devops-sharedinfra-eks" = "owned"
    "k8s.io/cluster-autoscaler/enabled"              = "TRUE"
  }

  cluster_service_cidr = "10.100.0.0/16"

}

