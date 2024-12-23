provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "example" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "example_lambda"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "example-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.example.invoke_arn
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET ${var.path}"
  target    = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.arn
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}


output "api_url" {
  value = format("${aws_apigatewayv2_stage.api_stage.invoke_url}%s", "${var.path}")
}
