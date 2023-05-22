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
  ssm_parameter_path = format("%s-%s-ssm", local.environment, local.name) #SSM parameter secret name
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "Jenkins-setup"

  instance_type          = "t2.micro"
  key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id              = "subnet-eddcdzz4"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}