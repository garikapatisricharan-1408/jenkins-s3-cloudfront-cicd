output "s3_bucket_name" {
  description = "S3 bucket name for Jenkins credential"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for Jenkins credential"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name (app URL)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "jenkins_access_key_id" {
  description = "Jenkins IAM user access key (add to Jenkins credentials)"
  value       = aws_iam_access_key.jenkins_deployer.id
  sensitive   = true
}

output "jenkins_secret_access_key" {
  description = "Jenkins IAM user secret key (add to Jenkins credentials)"
  value       = aws_iam_access_key.jenkins_deployer.secret
  sensitive   = true
}
