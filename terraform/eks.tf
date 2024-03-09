# data "aws_caller_identity" "current" {}

# locals {
#   node_group_name        = "EKSCluster-node-group"
#   iam_role_policy_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy"
# }

resource "aws_eks_cluster" "eks-cluster" {
  name     = "EKSCluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.example-Amazon-EBS-csi-driver,
    aws_cloudwatch_log_group.eks_log_group,
  ]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "node-group"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks-cluster.name
  fargate_profile_name   = "frontend"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = module.vpc.private_subnets

  selector {
    namespace = "dev"
    labels = {
      env : "frontend"
    }
  }
}

resource "aws_cloudwatch_log_group" "eks_log_group" {
  name              = "/aws/eks/EKSCluster/cluster"
  retention_in_days = 7
}

resource "aws_eks_addon" "ebs-csi-driver" {
  cluster_name                = aws_eks_cluster.eks-cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [ aws_iam_role_policy_attachment.example-Amazon-EBS-csi-driver ]
}

