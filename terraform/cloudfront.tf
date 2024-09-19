variable "s3_bucket_name" {
  type = string
}

resource "aws_cloudfront_origin_access_control" "s3_origin_access" {
  name                              = "S3 bucker origin control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "cf_distribution" {

  enabled = true

  origin {
    domain_name              = "${var.s3_bucket_name}.s3.us-east-1.amazonaws.com"
    origin_id                = "s3Bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_origin_access.id
  }

  origin {
    domain_name = "${aws_api_gateway_rest_api.api_gw.id}.execute-api.us-east-1.amazonaws.com"
    origin_id   = "apigateway"
    origin_path = "/prod"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-api-key"
      value = aws_api_gateway_api_key.api_gw_key.value
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3Bucket"

    viewer_protocol_policy = "https-only"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern     = "/count"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apigateway"

    viewer_protocol_policy   = "https-only"
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}