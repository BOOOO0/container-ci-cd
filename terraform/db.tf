resource "aws_db_instance" "my_db" {
  identifier = "my-db"

  storage_type = "gp3"
  allocated_storage = 100

  engine = "mariadb"
  engine_version = "10.11.6"
  instance_class = "db.t3.small"
  # default db name
  db_name = "apidb"
  # master user
  username = "root"
  password = "rds!!#root123"

  multi_az = true

  skip_final_snapshot = true

  vpc_security_group_ids = [ aws_security_group.db_sg.id ]
  
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
}

resource "aws_db_subnet_group" "db_subnet_group" {
  
  name = "db-subnet-group"

  subnet_ids = module.vpc.database_subnets

  tags = {
    Name = "db-subnet-group"
  }
}