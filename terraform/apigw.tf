resource "aws_api_gateway_rest_api" "api_gw" {
  name        = "WebVisitorCounterAPI"
  description = "This is the api for website visitor counter"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api_gw_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "count"
}

resource "aws_api_gateway_method" "api_gw_method_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.api_gw_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "api_gw_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_resource.api_gw_resource.id
  http_method             = aws_api_gateway_method.api_gw_method_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_lambda_permission" "lambda_invoke_permission" {
  statement_id  = "WebVisitorCounterAPILambdaInvokePolicy"
  action        = "lambda:InvokeFunction"
  function_name = "WebVisitorCounter"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gw.execution_arn}/*"
}


resource "aws_api_gateway_deployment" "api_gw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_gw_resource.id,
      aws_api_gateway_method.api_gw_method_get.id,
      aws_api_gateway_integration.api_gw_lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_gw_stage" {
  deployment_id = aws_api_gateway_deployment.api_gw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  stage_name    = "prod"
}

resource "aws_api_gateway_api_key" "api_gw_key" {
  name = "WebVisitorCounterAPI"
}

resource "aws_api_gateway_usage_plan" "api_gw_usage_plan" {
  name        = "WebVisitorCounterPlan"
  description = "Usage plan for API"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gw.id
    stage  = aws_api_gateway_stage.api_gw_stage.stage_name
  }

  quota_settings {
    limit  = 5
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 5
  }
}

resource "aws_api_gateway_usage_plan_key" "api_gw_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_gw_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_gw_usage_plan.id
}
