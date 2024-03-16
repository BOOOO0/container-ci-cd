# resource "aws_eks_cluster" "eks-cluster" {
#   name     = "EKSCluster"
#   role_arn = aws_iam_role.example.arn

#   vpc_config {
#     subnet_ids = module.vpc.private_subnets
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
#     aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
#     aws_cloudwatch_log_group.eks_log_group,
#   ]
# }

# resource "aws_eks_node_group" "node_group" {
#   cluster_name    = aws_eks_cluster.eks-cluster.name
#   node_group_name = "node-group"
#   node_role_arn   = aws_iam_role.nodes.arn
#   subnet_ids      = module.vpc.private_subnets

#   scaling_config {
#     desired_size = 2
#     max_size     = 4
#     min_size     = 2
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

# resource "aws_eks_fargate_profile" "fargate_profile" {
#   cluster_name           = aws_eks_cluster.eks-cluster.name
#   fargate_profile_name   = "frontend"
#   pod_execution_role_arn = aws_iam_role.fargate.arn
#   subnet_ids             = module.vpc.private_subnets

#   selector {
#     namespace = "dev"
#     labels = {
#       env : "frontend"
#     }
#   }
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = "EKSCluster"
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true
  

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {

    one = {
     name = "node-group"

      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 6
      desired_size = 3
    }
  }

  fargate_profile_defaults = {
    
    selectors = [
      {
        namespace = "dev"
        labels = {
          env : "frontend"
        }
      }
    ]

    
  }
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.28.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}