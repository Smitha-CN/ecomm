variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "ecomm-app"
}

variable "ami_id" {
  default = "ami-0c02fb55956c7d316"  # Amazon Linux 2
}

variable "key_name" {
  description = "Name of the EC2 Key Pair"
  type        = string
}

variable "db_username" {
  type        = string
  description = "RDS DB username"
}

variable "db_password" {
  type        = string
  description = "RDS DB password"
  sensitive   = true
}
