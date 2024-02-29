resource "aws_instance" "jenkins" {
  subnet_id = aws_subnet.public_subnet_b.id

  ami = var.amazon_linux_2023_ami
  instance_type = var.t3_medium
  key_name = var.ec2_key

  vpc_security_group_ids = [ aws_security_group.jenkins_sg.id ]
  
  user_data = file("./script/jenkins.sh")

  tags = {
    Name = "jenkins"
  }
}