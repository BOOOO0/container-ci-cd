variable "cidr_vpc" {
  default = "10.0.0.0/16"
}

variable "amazon_linux_2023_ami" {
  default = "ami-0bfd23bc25c60d5a1"
}

variable "amazon_2023_tokyo" {
  default = "ami-039e8f15ccb15368a"
}

variable "t3_micro" {
  default = "t3.micro"
}

variable "ec2_key" {
  default = "tokyo_jenkins"
}

variable "t3_medium" {
  default = "t3.medium"
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "cluster_name" {
  default = "EKSCluster"
}