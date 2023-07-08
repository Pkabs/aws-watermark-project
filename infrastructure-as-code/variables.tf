# Lambda function variables
variable "data_rs_type" {
  type        = string
  description = "type of data resource"
  default     = "zip"
}

variable "data_rs_source_file" {
  type        = string
  description = "path to the python source file"
  default     = "D:/Visual_Studio_Code/AwsRestartCapStoneProject/lambda_function.py"
}

variable "data_rs_output_filemode" {
  type        = string
  description = "Output file mode"
  default     = "0666"
}

variable "data_rs_output_path" {
  type        = string
  description = "Output path of the zipped file"
  default     = "D:/Visual_Studio_Code/AwsRestartCapstoneProject/infrastructure-as-code/lambda-function-payload.zip"
}


variable "lambda_functionName" {
  type        = string
  description = "The name of Lambda function"
  default     = "TerraWaterMarkLambda"
}

variable "lambda_description" {
  type        = string
  description = "The description of Lambda function"
  default     = "Function to add water mark on images"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda function runtime"
  default     = "python3.8"
}

# variable "lambda_file_name" {
#   type        = string
#   description = "Lambda function zip filename"
#   default     = "${path.module}/lambda-function-payload.zip"
# }

# variable "lambda_source_code_hash" {
#   type        = string
#   description = "Source code hash"
#   default     = "D:/Visual_Studio_Code/AwsRestartCapStoneProject/my_lambda_function.zip"
# }

variable "lambda_file_handler" {
  type        = string
  description = "Lambda function code entry point"
  default     = "lambda_function.lambda_handler"
}