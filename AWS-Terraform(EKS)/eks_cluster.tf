resource "aws_eks_cluster" "main" {
    name = "${var.project_name}-${environment}-eks-cluster"
    role_arn = aws_iam_role.eks_cluster.arn
    version = "1.32"
}