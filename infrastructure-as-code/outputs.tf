output "lambda_function_arn" {
  description = "ARN of Lambda function"

  value = aws_lambda_function.watermark_lambda.arn
}

output "api_url" {
  value = aws_api_gateway_stage.api_gw_stage.invoke_url
}

output "api_gateway_arn" {
  description = "ARN of API Gateway Role"

  value = aws_iam_role.api_gateway_role.arn
}

