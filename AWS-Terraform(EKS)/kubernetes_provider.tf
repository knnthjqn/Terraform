data "aws_eks_cluster_auth" "main" {
    name = aws_eks_cluster.main.name
}

provider "kubernetes" {
    host = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64encode(aws_eks_cluster.main.certificate_authority[0].data)
    token = aws_eks_cluster_auth.main.token
}