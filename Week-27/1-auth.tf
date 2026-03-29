terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Use latest version if possible
    }
  }

  backend "s3" {
    bucket  = "jenkins-tf-state-z1"       # your S3 bucket
    key     = "jenkins/terraform.tfstate" # path inside the bucket
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

