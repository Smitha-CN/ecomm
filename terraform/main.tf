provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "ecomm-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = "t2.medium"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install java-openjdk11 -y
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum install jenkins -y
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.0.2"

  identifier = "ecomm-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "ecommerce"
  username          = var.db_username
  password          = var.db_password
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_ids             = module.vpc.private_subnets

  tags = {
    Name = "ecomm-db"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "static_content" {
  bucket = "${var.project_name}-static-content"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "EcommerceStaticContent"
    Environment = "dev"
  }
}

resource "aws_cognito_user_pool" "main" {
  name = "ecomm-user-pool"
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "ecomm-client"
  user_pool_id = aws_cognito_user_pool.main.id
  generate_secret = false
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "ecomm-identity-pool"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id = aws_cognito_user_pool_client.main.id
    provider_name = aws_cognito_user_pool.main.endpoint
  }
}
