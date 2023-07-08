output "lambda_function_arn" {
  description = "ARN of Lambda function"

  value = aws_lambda_function.watermark_lambda.arn

}