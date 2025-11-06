# Generate random suffix for bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  input_bucket_name  = var.input_bucket_name != "" ? var.input_bucket_name : "${var.project_name}-${var.environment}-input-${random_id.bucket_suffix.hex}"
  output_bucket_name = var.output_bucket_name != "" ? var.output_bucket_name : "${var.project_name}-${var.environment}-output-${random_id.bucket_suffix.hex}"
}

# Input Bucket
resource "aws_s3_bucket" "input" {
  bucket = local.input_bucket_name
  
  tags = merge(
    var.tags,
    {
      Name = local.input_bucket_name
      Type = "Input"
    }
  )
}

# Input Bucket - Versioning
resource "aws_s3_bucket_versioning" "input" {
  bucket = aws_s3_bucket.input.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Input Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "input" {
  bucket = aws_s3_bucket.input.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Input Bucket - Block Public Access
resource "aws_s3_bucket_public_access_block" "input" {
  bucket = aws_s3_bucket.input.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Input Bucket - Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "input" {
  bucket = aws_s3_bucket.input.id
  
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
  
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Output Bucket
resource "aws_s3_bucket" "output" {
  bucket = local.output_bucket_name
  
  tags = merge(
    var.tags,
    {
      Name = local.output_bucket_name
      Type = "Output"
    }
  )
}

# Output Bucket - Versioning
resource "aws_s3_bucket_versioning" "output" {
  bucket = aws_s3_bucket.output.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Output Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "output" {
  bucket = aws_s3_bucket.output.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Output Bucket - Block Public Access
resource "aws_s3_bucket_public_access_block" "output" {
  bucket = aws_s3_bucket.output.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output Bucket - Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "output" {
  bucket = aws_s3_bucket.output.id
  
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
  
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    
    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

