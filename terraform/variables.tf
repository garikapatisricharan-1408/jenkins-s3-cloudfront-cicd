variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name — used as prefix for all resources"
  type        = string
  default     = "frontend-app"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID for Jenkins security group"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR block for admin SSH/Jenkins access (your IP/32)"
  type        = string
  default     = "0.0.0.0/0" # Override with your actual IP in prod!
}
