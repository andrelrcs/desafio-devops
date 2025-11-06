output "input_bucket_id" {
  description = "The ID of the input S3 bucket"
  value       = aws_s3_bucket.input.id
}

output "input_bucket_arn" {
  description = "The ARN of the input S3 bucket"
  value       = aws_s3_bucket.input.arn
}

output "input_bucket_name" {
  description = "The name of the input S3 bucket"
  value       = aws_s3_bucket.input.bucket
}

output "output_bucket_id" {
  description = "The ID of the output S3 bucket"
  value       = aws_s3_bucket.output.id
}

output "output_bucket_arn" {
  description = "The ARN of the output S3 bucket"
  value       = aws_s3_bucket.output.arn
}

output "output_bucket_name" {
  description = "The name of the output S3 bucket"
  value       = aws_s3_bucket.output.bucket
}
