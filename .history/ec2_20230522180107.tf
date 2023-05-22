locals {
  name        = "key"
  region      = "ap-south-1"
  environment = "dev"
  additional_tags = {
    Owner      = "squareops"
    Expires    = "Never"
    Department = "Engineering"
  }
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "Jenkins-setup"

  instance_type          = "t2.medium"
  ami                    = "ami-0a065b41e0d7afc5f"
  key_name               = "jenkins-setup"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data              = file("pritunl.sh")
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  create_iam_instance_profile = true
  iam_role_name               = format("%s-%s-instance-role", local.Environment, local.Name)
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

}

#security group for pritunl
resource "aws_security_group" "jenkins-sg" {
  name        = "allow_tls_pritunl"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tls"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "jenkins-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1b", "ap-south-1c"]
  private_subnets = ["10.0.6.0/24"]
  public_subnets  = ["10.0.104.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}