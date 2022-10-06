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
  name = "demo.local"
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

resource "aws_lambda_permission" "api-gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_country.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*/*"
}


/*
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "demo.local"
  type    = "A"

  alias {
    name                   = module.api_gateway.apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway.apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
*/

resource "aws_acm_certificate" "cert" {
  domain_name       = "testing.tensouthtech.com"
  validation_method = "EMAIL"

  validation_option {
    domain_name       = "testing.tensouthtech.com"
    validation_domain = "tensouthtech.com"
  }
}

resource "aws_s3_bucket" "cdn" {
  bucket = "localstack-cdn"
  tags   = var.tags
}

resource "aws_s3_bucket" "cdnlog" {
  bucket = "localstack-cdn-log"
  tags   = var.tags
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = ["cdn.tensouthtech.com"]

  comment             = "this is my cloudfront"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = aws_s3_bucket.cdn.bucket
  }

  logging_config = {
    bucket = "${aws_s3_bucket.cdnlog.bucket}.s3.amazonaws.com"
  }

  origin = {
    something = {
      domain_name = aws_acm_certificate.cert.domain_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    s3_one = {
      domain_name = "${aws_s3_bucket.cdn.bucket}.s3.amazonaws.com"
      s3_origin_config = {
        origin_access_identity = aws_s3_bucket.cdn.bucket
      }
    }
  }

  default_cache_behavior = {
    target_origin_id           = "something"
    viewer_protocol_policy     = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3_one"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}