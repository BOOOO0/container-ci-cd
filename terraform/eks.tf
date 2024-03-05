# data "aws_caller_identity" "current" {}

# locals {
#   node_group_name        = "EKSCluster-node-group"
#   iam_role_policy_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy"
# }

module "eks" {
    source = "terraform-aws-modules/eks/aws"

    cluster_endpoint_public_access = true
    
    cluster_name = "EKSCluster"
    cluster_version = "1.27"

    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    eks_managed_node_group_defaults = {
        ami_type               = "AL2_x86_64" # 
        disk_size              = 20           # EBS 사이즈
        instance_types         = ["t3.medium"]
        use_custom_launch_template = false
        # cluster-autoscaler에 사용 될 IAM 등록

        min_size = 2
        max_size = 4
        desired_size = 2

        # iam_role_additional_policies = ["${local.iam_role_policy_prefix}/${module.iam_policy_autoscaling.name}"]
    }
    
    # cluster_addons = {
    #     kube-proxy = {
    #         most_recent = true
    #     }
    #     vpc-cni = {
    #         most_recent = true
    #     }
    # }

    # fargate_profile_defaults = {
    #     iam_role_additional_policies = {
    #         additional = aws_iam_policy.additional.arn
    #     }
    # }
}

resource "aws_iam_policy" "additional" {
  name = "iam-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

        # depends_on = [
        #     aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
        #     aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
        #     aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
        # ]