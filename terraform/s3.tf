locals {
  s3_bucket_name = "transportes-flores-vargas-${data.aws_caller_identity.current.account_id}-${var.s3_bucket_suffix}"
}

resource "aws_s3_bucket" "app" {
  bucket = local.s3_bucket_name

  tags = {
    Name = "tfv-app-data"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "ec2_app" {
  name = "tfv-ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "tfv-ec2-app-role"
  }
}

resource "aws_iam_role_policy" "ec2_s3_app" {
  name = "tfv-s3-app-bucket"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.app.arn
      },
      {
        Sid    = "ObjectRW"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.app.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "tfv-ec2-app-profile"
  role = aws_iam_role.ec2_app.name

  tags = {
    Name = "tfv-ec2-app-profile"
  }
}
