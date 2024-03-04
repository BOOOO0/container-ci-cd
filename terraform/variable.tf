variable "cidr_vpc" {
  default = "10.0.0.0/16"
}

variable "amazon_linux_2023_ami" {
  default = "ami-0bfd23bc25c60d5a1"
}

variable "t3_micro" {
  default = "t3.micro"
}

variable "ec2_key" {
  default = "my_key"
}

variable "t3_medium" {
  default = "t3.medium"
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
}

variable "cluster_name" {
  default = "EKSCluster"
}