resource "aws_instance" "jenkins" {
  subnet_id = module.vpc.public_subnets[1]

  ami = var.amazon_linux_2023_ami
  instance_type = var.t3_medium
  key_name = var.ec2_key

  vpc_security_group_ids = [ aws_security_group.jenkins_sg.id ]
  
  user_data = file("./script/jenkins.sh")

  tags = {
    Name = "jenkins"
  }
}

output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}