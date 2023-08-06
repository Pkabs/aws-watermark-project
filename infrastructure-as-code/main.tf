# Create S3 bucket that will have original photos
resource "aws_s3_bucket" "original_bucket" {
  bucket = "terra-original-photos-bucket"
  #force_destroy = true

  tags = {
    Name        = "Terra Original Photos Bucket"
    Environment = "Dev"
  }
}

# Create a file object for original bucket as a sample picture
resource "aws_s3_object" "object-for-original-bucket" {
  bucket = aws_s3_bucket.original_bucket.id
  key    = "Images/SamplePicture.png"
  source = "BucketFiles/samplepicture.png"
  etag   = filemd5("BucketFiles/samplepicture.png")
}


# Create S3 bucket that will have watermarked photos
resource "aws_s3_bucket" "watermarked_bucket" {
  bucket = "terra-watermarked-photos-bucket"
  #force_destroy = true

  tags = {
    Name        = "Terra Water Marked Photos Bucket"
    Environment = "Dev"
  }
}

# Create S3 folder object for storing watermarked images
resource "aws_s3_object" "object-for-watermarked-bucket" {
  bucket = aws_s3_bucket.watermarked_bucket.id
  key    = "Images/"
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "TerraWaterMarkLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach IAM policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_1" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create permission to allow execution from S3 bucket
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.watermark_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.original_bucket.arn
}

# Create an S3 bucket notification for png images to trigger the Lambda function
resource "aws_s3_bucket_notification" "png_bucket_notification" {
  bucket = aws_s3_bucket.original_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.watermark_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "Images/"
    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}


# Create a data resource for creating a zip file for python source file
data "archive_file" "lambda_zipfile" {
  type             = var.data_rs_type
  source_file      = var.data_rs_source_file
  output_file_mode = var.data_rs_output_filemode
  output_path      = var.data_rs_output_path
}

# Create a Lambda function using local zipped file
resource "aws_lambda_function" "watermark_lambda" {

  function_name = var.lambda_functionName
  description   = var.lambda_description
  handler       = var.lambda_file_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/lambda-function-payload.zip"
  layers        = [aws_lambda_layer_version.lambda_pillow_layer.arn]

  source_code_hash = data.archive_file.lambda_zipfile.output_base64sha256
}

# # Create a data resource for creating a zip file for Pillow library
# data "archive_file" "lambda_layers_pillow_library" {
#   type             = "zip"
#   output_file_mode = "0666"
#   source_dir       = "D:/Visual_Studio_Code/AwsRestartCapStoneProject/lambda-dependencies/"
#   output_path      = "D:/Visual_Studio_Code/TerraformProjects/AwsRestartCapstoneProject/pillow-library-9-5-0.zip"
# }

# Create a lambda layer resource for the pillow library
resource "aws_lambda_layer_version" "lambda_pillow_layer" {
  layer_name  = "PillowLayer9_5_0"
  description = "Pillow library v9.5.0"
  filename    = "${path.module}/pillow-lambda-layer.zip"

  compatible_architectures = [
    "x86_64"
  ]

  compatible_runtimes = [
    "python3.8"
  ]
  source_code_hash = filebase64sha256("pillow-lambda-layer.zip")
}

# Create an IAM role for the API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "TerraApiGatewayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach IAM policies to the API Gateway role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment_1" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudWatch_policy_attachment_2" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Create a REST API Gateway
resource "aws_api_gateway_rest_api" "file_upload_rest_api" {
  name        = "TerraFileUploadRestAPI"
  description = "REST API to upload files"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  binary_media_types = ["*/*"]
}

# Create a resource for the API Gateway
resource "aws_api_gateway_resource" "bucket_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id
  parent_id   = aws_api_gateway_rest_api.file_upload_rest_api.root_resource_id
  path_part   = "{bucketname}"
}

# Create a resource for the API Gateway
resource "aws_api_gateway_resource" "dir_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id
  parent_id   = aws_api_gateway_resource.bucket_resource.id
  path_part   = "Images"
}


# Create a nested resource for the API Gateway
resource "aws_api_gateway_resource" "file_name_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id
  parent_id   = aws_api_gateway_resource.dir_resource.id
  path_part   = "{filename}"
}


# Create a method for the API Gateway
resource "aws_api_gateway_method" "file_upload_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_upload_rest_api.id
  resource_id   = aws_api_gateway_resource.file_name_resource.id
  http_method   = "PUT"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.bucketname" = true,
    "method.request.path.filename"   = true
  }
}

resource "aws_api_gateway_method_response" "file_upload_api_method_resp" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id
  resource_id = aws_api_gateway_resource.file_name_resource.id
  http_method = aws_api_gateway_method.file_upload_api_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Create an integration for the API Gateway
resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.file_upload_rest_api.id
  resource_id             = aws_api_gateway_resource.file_name_resource.id
  http_method             = aws_api_gateway_method.file_upload_api_method.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/{bucketname}/Images/{filename}"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_parameters = {
    "integration.request.path.bucketname" = "method.request.path.bucketname",
    "integration.request.path.filename"   = "method.request.path.filename"
  }
}

resource "aws_api_gateway_integration_response" "api_integration_resp" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id
  resource_id = aws_api_gateway_resource.file_name_resource.id
  http_method = aws_api_gateway_method.file_upload_api_method.http_method
  status_code = aws_api_gateway_method_response.file_upload_api_method_resp.status_code
}

# Create a deployment for the API Gateway
resource "aws_api_gateway_deployment" "file_upload_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_rest_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.file_upload_rest_api.body,
      aws_api_gateway_resource.bucket_resource.id,
      aws_api_gateway_resource.dir_resource.id,
      aws_api_gateway_resource.file_name_resource.id,
      aws_api_gateway_method.file_upload_api_method.id,
      aws_api_gateway_integration.api_integration.id,
    aws_api_gateway_integration_response.api_integration_resp.id]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_method.file_upload_api_method, aws_api_gateway_integration.api_integration]
}

# Create a stage area for the api gateway
resource "aws_api_gateway_stage" "api_gw_stage" {
  deployment_id = aws_api_gateway_deployment.file_upload_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.file_upload_rest_api.id
  stage_name    = "TerraDev"
}