#!bin/bash
yum update
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf update
dnf install java-17-amazon-corretto -y

dnf install docker
systemctl enable --now docker
usermod -aG docker ec2-user
newgrp docker
systemctl restart docker

yum install jenkins -y
systemctl enable --now jenkins

