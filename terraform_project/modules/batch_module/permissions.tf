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
          "${aws_s3_bucket.processed_zone_bucket.arn}",
          "${aws_s3_bucket.glue_script_bucket.arn}/*",
          "${aws_s3_bucket.glue_script_bucket.arn}"
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
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/crawlers:log-stream:*"
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
          "glue:CreateTable",
          "glue:BatchGetPartition",
          "glue:BatchCreatePartition",
          "glue:UpdateTable",
          "glue:UpdatePartition"
        ],
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.data_catalog.name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.data_catalog.name}/*"
        ]
      },

      {
        Effect = "Allow",
        Action = "*",
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:session/*"
        ]
      },

      # {
      #     "Effect": "Allow",
      #     "Action": "iam:PassRole",
      #     "Resource": "arn:aws:iam::813276439036:role/glue_role",
      #     "Condition": {
      #         "StringEquals": {
      #             "iam:PassedToService": "glue.amazonaws.com"
      #         }
      #     }
      # }

    ]
  })
}

resource "aws_iam_role" "glue_role" {
  name = "glue_role"

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

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}


## LAMBDA

resource "aws_iam_role" "lambda_watcher_role" {
  name               = "lambda_watcher_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_watcher_policy" {
  name        = "rtad-lambda_watcher-policy"
  description = "Policy to allow Lambda to access specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
       {
            Effect = "Allow",
            Action = "glue:StartJobRun",
            Resource =  "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/*"
        },

      {
            Effect =  "Allow",
            Action = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            Resource = [
                "${aws_s3_bucket.reference_bucket.arn}/*",
                "${aws_s3_bucket.reference_bucket.arn}"
            ]
        },

        {
            Effect = "Allow",
            Action = [
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            Resource = [
                "${aws_s3_bucket.reference_bucket.arn}/*",
                "${aws_s3_bucket.reference_bucket.arn}"
            ]
        },

        {
            Effect = "Allow",
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
            ],
            Resource = ["arn:aws:logs:*:*:*"]
        }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_watcher_role_attach" {
  role       = aws_iam_role.lambda_watcher_role.name
  policy_arn = aws_iam_policy.lambda_watcher_policy.arn
}


## BUCKET NOTIFICATIONS

resource "aws_lambda_permission" "allow_reference_bucket_lambda_watcher" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_watcher.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.reference_bucket.arn
}



