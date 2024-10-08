module "plugins" {
    source = "./plugins"

    oidc_issuer_arn = local.oidc_issuer_arn
    TF_ENVIRONMENT = "devops"
    cluster_name   = local.name_prefix
    vpc_id         = var.vpc_id
}

# arn:aws:iam::246613758532:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/73BC9E1613CA1BB7BAC3356BEB372119
# arn:aws:iam::246613758532:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/BEF0B5362D36075D28B6FD3BCEDDE6D3
# arn:aws:iam::246613758532:oidc-provider/BEF0B5362D36075D28B6FD3BCEDDE6D3.gr7.ap-southeast-1.eks.amazonaws.com
# arn:aws:iam::246613758532:role/mst-production-sharedinfra-eks20210723133115225700000002
#                                        /oidc.eks.ap-southeast-1.amazonaws.com/id/73BC9E1613CA1BB7BAC3356BEB372119