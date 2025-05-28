output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "s3_website_url" {
  value = aws_s3_bucket.static_content.website_endpoint
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
}
