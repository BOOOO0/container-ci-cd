resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-routing-table"
  }
}

resource "aws_route_table_association" "public_rtb_association_1" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public_rtb_association_2" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route  {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.my_nat.id
  }

  tags = {
    Name = "private-routing-table"
  }
}

resource "aws_route_table_association" "private_rtb_association_1" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_route_table_association" "private_rtb_association_2" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_route_table" "db_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "db-routing-table"
  }
}

resource "aws_route_table_association" "db_rtb_association_1" {
  subnet_id      = aws_subnet.db_subnet_a.id
  route_table_id = aws_route_table.db_rtb.id
}

resource "aws_route_table_association" "db_rtb_association_2" {
  subnet_id      = aws_subnet.db_subnet_b.id
  route_table_id = aws_route_table.db_rtb.id
}