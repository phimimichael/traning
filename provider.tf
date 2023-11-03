provider "aws" {
  region = var.region
}
terraform {
  backend "s3" {
    bucket = "git-bucket-admin-contributor"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

