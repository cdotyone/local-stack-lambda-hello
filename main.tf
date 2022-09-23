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

resource "aws_s3_bucket" "b" {
  bucket = "localstack-s3-lambda"
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "public-read"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.b.id
  key    = "countries.json"
  source = "${path.module}/countries.json"

  etag = filemd5("${path.module}/countries.json")
}

module "lambda" {
  source = "./modules/lambda"
  name   = "s3lambda"
  environment = {
    bucket = aws_s3_bucket.b.id
    env    = var.tags.env
  }
  tags = var.tags
}

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