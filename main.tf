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
    s3       = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = "localstack-s3-dynamo"
  tags   = var.tags
}

resource "aws_dynamodb_table" "countries_table" {
  name           = "countries"
  billing_mode   = "PROVISIONED"
  read_capacity  = "30"
  write_capacity = "30"
  attribute {
    name = "countryCode"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }

  hash_key  = "countryCode"
  range_key = "name"

  provisioner "local-exec" {
    command = "python load.py"
  }
}

module "lambda_get" {
  source = "./modules/lambda_get"
  name   = "dyna-get"
  environment = {
    env    = var.tags.env
  }
  tags = var.tags
}

module "lambda_list" {
  source = "./modules/lambda_list"
  name   = "dyna-list"
  environment = {
    env    = var.tags.env
  }
  tags = var.tags
}


/*
resource "aws_iam_role_policy" "test_policy" {
  name = "access_s3"
  role = module.lambda.role_name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : ["${aws_s3_bucket.b.arn}/*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : ["${aws_s3_bucket.b.arn}/*"]
      }
  ]
}
EOF
}
*/