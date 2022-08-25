terraform {
  backend "local" {}
}

# Public Cloud Configuration
provider "aws" {
  region     = "us-east-2"
  access_key = "fake"
  secret_key = "fake"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3     = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }
}

module "lambda" {
  source = "./modules/lambda"
  name   = "hello"
  tags   = var.tags
}