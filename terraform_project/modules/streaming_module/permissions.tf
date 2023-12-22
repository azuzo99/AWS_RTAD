resource "aws_iam_role" "kinesis_firehose_role" {
  name               = "kinesis_firehose_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role_policy.json

  depends_on = [ data.aws_iam_policy_document.firehose_assume_role_policy, aws_iam_policy.kinesis_delivery_stream_policy ]
}

resource "aws_iam_role_policy_attachment" "firehose_stream_attach" {
  role       = aws_iam_role.kinesis_firehose_role.name
  policy_arn = aws_iam_policy.kinesis_delivery_stream_policy.arn

  depends_on = [ aws_iam_role.kinesis_firehose_role ]
}

data "aws_iam_policy_document" "firehose_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "kinesis_delivery_stream_policy" {
  name        = "firehose-policy"
  description = "Policy to allow Firehose to access resources"
  policy      = data.aws_iam_policy_document.firehose_policy.json
}

data "aws_iam_policy_document" "firehose_policy" {
  # Glue related permissions
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:database/${var.glue_data_catalog_name}",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:table/${var.glue_data_catalog_name}/${var.firehose_glue_catalog_table_name}",
    ]
  }

  # Kafka related permissions
  statement {
    actions = [
      "kafka:GetBootstrapBrokers",
      "kafka:DescribeCluster",
      "kafka:DescribeClusterV2",
      "kafka-cluster:Connect",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${var.account_id}:cluster/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
  }

  # Kafka topic related permissions
  statement {
    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:ReadData",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${var.account_id}:topic/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
  }

  # Kafka group related permissions
  statement {
    actions = [
      "kafka-cluster:DescribeGroup",
    ]
    resources = [
      "arn:aws:kafka:${var.aws_region}:${var.account_id}:group/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*"
    ]
  }

  # S3 related permissions
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "${var.raw_zone_bucket_arn}",
      "${var.raw_zone_bucket_arn}/*",
    ]
  }

  # Lambda related permissions
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    ]
  }

  # KMS related permissions for S3
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${var.aws_region}.amazonaws.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*",
        "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
      ]
    }
  }

  # Logs related permissions
  statement {
    actions = [
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesisfirehose/${var.kdf_delivery_stream_name}:log-stream:*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%:log-stream:*",
    ]
  }

  # Kinesis related permissions
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
    ]
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${aws_kinesis_stream.kds_stream.name}",
    ]
  }

  # KMS related permissions for Kinesis
  statement {
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "kinesis.${var.aws_region}.amazonaws.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:kinesis:arn"
      values = [
        "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${aws_kinesis_stream.kds_stream.name}",
      ]
    }
  }
}
