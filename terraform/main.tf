# Configure AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Lambda Function
resource "aws_lambda_function" "csv_processor" {
  filename         = "app.zip"  # You'll need to zip your app files
  function_name    = "csv-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.10"
  timeout         = 30
  memory_size     = 128

  environment {
    variables = {
      OUTPUT_BUCKET = module.s3_buckets.output_bucket_name
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "csv_processor_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic Lambda permissions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "csv_processor_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${module.s3_buckets.input_bucket_arn}/*",
          "${module.s3_buckets.output_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# S3 Event Trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_buckets.input_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }
}

# Lambda permission to allow S3 trigger
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_buckets.input_bucket_arn
}

# Use existing S3 module
module "s3_buckets" {
  source = "./modules/s3"

  project_name      = "csv-processor"
  environment       = "prod"
  enable_versioning = true
}