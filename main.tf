terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0" }
    random = { source = "hashicorp/random", version = ">= 3.5" }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Generate a unique bucket suffix so names don't collide globally
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "tf-site-${random_id.suffix.hex}"
}

# S3 bucket
resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  tags = {
    project = "lab3-terraform-github-actions"
  }
}

# Public access block at the BUCKET level set to false so ACLs can work (lab only)
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Website configuration (index + error to index)
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" }

  # Ensure PAB is set first
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Enable object ACLs (required for public-read ACLs)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# Make the bucket publicly readable via ACL (lab only)
resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.site]
}

# Upload the page (and make the object itself public)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
  acl          = "public-read"

  # Ensure ACLs/ownership controls applied before uploading
  depends_on = [aws_s3_bucket_acl.site]
}

# --------- Outputs (keep these here OR remove outputs.tf) ---------
output "bucket_name" {
  value       = aws_s3_bucket.site.bucket
  description = "Name of the S3 bucket"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
  description = "S3 static website URL"
}
