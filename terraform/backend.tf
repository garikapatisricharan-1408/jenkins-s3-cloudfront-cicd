# Remote state stored in S3 — prevents state file loss
# Create this bucket manually BEFORE running terraform init
terraform {
  backend "s3" {
    bucket         = "sricharan-terraform-state"
    key            = "jenkins-s3-cloudfront/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
