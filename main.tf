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
    acm            = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://LOCALHOST:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
  }
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

module "lambda_country" {
  source = "./modules/lambda"
  name   = "dyna-country"
  environment = {
    env = var.tags.env
  }
  tags = var.tags
}

resource "aws_route53_zone" "main" {
  name = local.domain_name
}

# API Gateway
resource "aws_apigatewayv2_api" "apigw" {
  name          = "apidemo"
  description   = "My HTTP API Gateway"
  protocol_type = "HTTP"

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.apigw.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "country" {
  api_id             = aws_apigatewayv2_api.apigw.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = module.lambda_country.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "list_route" {
  api_id           = aws_apigatewayv2_api.apigw.id
  route_key        = "ANY /country"
  api_key_required = false
  operation_name   = "list"
  target           = "integrations/${aws_apigatewayv2_integration.country.id}"
}

locals {
  domain_name       = "tensouthtech.com"
  subdomain         = "www"
  secret_user_agent = "SECRET-STRING"
  bucket_name       = "localstack-website"
  index_document    = "index.html"
}

data "aws_canonical_user_id" "current" {}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name               = local.domain_name
  zone_id                   = aws_route53_zone.main.id
  subject_alternative_names = ["${local.subdomain}.${local.domain_name}", "${local.domain_name}"]
}

resource "aws_cloudfront_distribution" "cdn" {
  http_version = "http2"

  origin {
    origin_id   = "origin-${local.bucket_name}"
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    #aws_s3_bucket_website_configuration.website.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = local.secret_user_agent
    }
  }

  enabled             = true
  default_root_object = local.index_document

  aliases = concat([local.bucket_name])

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id = "origin-${local.bucket_name}"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

resource "random_pet" "this" {
  length = 2
}
