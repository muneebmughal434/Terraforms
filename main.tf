terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0" }
    random = { source = "hashicorp/random", version = ">= 3.5" }
  }
}

provider "aws" {
  region = var.aws_region
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

# Allow public website hosting (for lab/testing only)
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Public read policy for website objects (testing only)
data "aws_iam_policy_document" "public_read" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
}

# Upload the page
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
  description = "Open this URL to view the site after apply."
}
