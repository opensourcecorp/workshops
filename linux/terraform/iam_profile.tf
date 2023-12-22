data "aws_caller_identity" "current" {}

resource "aws_iam_role" "this" {
  name = "ec2-s3-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_lambda_admin" {
  name        = "s3_lambda_admin_policy"
  description = "Admin access to S3 and Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
          "lambda:*"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_read" {
  name        = "ec2_read_policy"
  description = "Read access to EC2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:Describe*"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "iam:*Role*"
        ],
        Effect = "Allow",
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_lambda_admin_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_lambda_admin.arn
}

resource "aws_iam_role_policy_attachment" "ec2_read_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ec2_read.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "ec2-lambda-s3"
  role = aws_iam_role.this.name
}
