variable "cidr_vpc" {
  default = "172.5.0.0/16"
}

variable "cidr_public_subnet_a" {
  default = "172.5.0.0/24"
}

variable "cidr_private_subnet_a" {
  default = "172.5.1.0/24"
}

variable "cidr_db_subnet_a" {
  default = "172.5.3.0/24"
}

variable "cidr_public_subnet_b" {
  default = "172.5.10.0/24"
}

variable "cidr_private_subnet_b" {
  default = "172.5.11.0/24"
}

variable "cidr_db_subnet_b" {
  default = "172.5.13.0/24"
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