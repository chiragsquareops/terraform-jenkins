locals {
  name        = "key"
  region      = "ap-south-1"
  environment = "prod"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
}

module "key_pair" {
  source             = "squareops/keypair/aws"
  key_name           = format("%s-%s-kp", local.environment, local.name)
  environment        = local.environment
  ssm_parameter_path = format("%s-%s-ssm", local.environment, local.name)
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "Jenkins-setup"

  instance_type          = "t2.micro"
  key_name               = module.key_pair.key_pair_name
  monitoring             = true
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.pritunl-sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = file("pritunl.sh")
  tags = {
    Terraform   = "true"
    Environment = "dev"
}

#security group for pritunl
resource "aws_security_group" "pritunl-sg" {
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
#pritunl ec2 instance
module "pritunl_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 3.0"
  name                   = "pritunl"
  ami                    = "ami-0530ca8899fac469f"
  instance_type          = "t3a.small"
  key_name               = "chirag-js"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.pritunl-sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = file("pritunl.sh")
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}