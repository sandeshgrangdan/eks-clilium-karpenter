output "private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = module.key_pair.private_key_pem
  sensitive   = true
}

output "oidc_issuer_arn" {
  value = local.oidc_issuer_arn
}

output "eks_managed_node_group_role_arn" {
  value = module.eks_managed_node_group.iam_role_arn
}