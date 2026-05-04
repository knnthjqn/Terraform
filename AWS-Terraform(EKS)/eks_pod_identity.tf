resource "aws_eks_pod_identity_association" "eks_app" {
    cluster_name = aws_eks_cluster.main.name
    namespace = local.app_namespace
    service_name = local.app_service_name
    role_arn = aws_iam_role.eks_app_pod.arn
}