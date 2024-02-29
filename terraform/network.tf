resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_vpc

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {

  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_public_subnet_a

  map_public_ip_on_launch = true

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_a" {
    
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_private_subnet_a

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "db_subnet_a" {
  
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_db_subnet_a

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "db-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {

  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_public_subnet_b

  map_public_ip_on_launch = true

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_subnet" "private_subnet_b" {
    
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_private_subnet_b

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_subnet" "db_subnet_b" {
  
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = var.cidr_db_subnet_b

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "db-subnet-b"
  }
}

resource "aws_internet_gateway" "my_igw" {

  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet_a.id

  depends_on = [ aws_internet_gateway.my_igw ]

  tags = {
    Name = "my-nat"
  }
}