module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  azs  = var.azs
  cidr = var.cidr_vpc

  # NAT게이트웨이를 생성합니다.
  enable_nat_gateway = true
  # NAT게이트웨이를 1개만 생성합니다.
  single_nat_gateway = true



  public_subnets = [for k, v in var.azs:
                      cidrsubnet(var.cidr_vpc, 8, k)]

  private_subnets = [for k, v in var.azs:
                      cidrsubnet(var.cidr_vpc, 8, k + 20)]

  database_subnets = [for k, v in var.azs:
                      cidrsubnet(var.cidr_vpc, 8, k + 40)]                   

  create_database_subnet_route_table     = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/EKSCluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/EKSCluster" = "shared"
  }
}