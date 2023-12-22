## CRAWLERS
resource "aws_iam_policy" "glue_policy" {
  name        = "rtad-glue-policy"
  description = "Policy to allow Glue to access specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
        Resource = [
          "${aws_s3_bucket.reference_bucket.arn}/*",
          "${aws_s3_bucket.reference_bucket.arn}",
          "${aws_s3_bucket.raw_zone_bucket.arn}/*",
          "${aws_s3_bucket.raw_zone_bucket.arn}",
          "${aws_s3_bucket.processed_zone_bucket.arn}/*",
          "${aws_s3_bucket.processed_zone_bucket.arn}"
        ]
      },

      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/crawlers:*",
            "arn:aws:logs:eu-central-1:813276439036:log-group:/aws-glue/crawlers:log-stream:*"
        ]
      },

      {
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:CreateTable"
        ],
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.data_catalog.name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.data_catalog.name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "glue_crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}