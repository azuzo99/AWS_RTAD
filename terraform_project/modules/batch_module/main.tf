resource "aws_s3_bucket" "reference_bucket" {
  bucket = var.reference_bucket_name

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_s3_bucket_versioning" "reference_bucket_versioning" {
  bucket = aws_s3_bucket.reference_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "reference_data" {
  bucket = aws_s3_bucket.reference_bucket.id
  key    = var.reference_data_filename
  source = "../templates/S3_Buckets_objects/reference_data/${var.reference_data_filename}"

  depends_on = [aws_s3_bucket.reference_bucket, aws_s3_bucket_versioning.reference_bucket_versioning]
}

resource "aws_lambda_function" "lambda_watcher" {
  filename      = data.archive_file.lambda_code.output_path
  source_code_hash = data.archive_file.lambda_code.output_base64sha256
  function_name = "lambda_watcher"
  role          = aws_iam_role.lambda_watcher_role.arn
  handler       = "${var.lambda_code_filename}.lambda_handler"
  timeout       = 15
  runtime       = "python3.11"


  environment {
    variables = {
      versioned_bucket = "${aws_s3_bucket.reference_bucket.id}",
      job_name = "${var.glue_script_filename}",

    }
  }

  logging_config {
    log_format = "Text"
    log_group = "${aws_cloudwatch_log_group.batch_log_group.name}/lambda_watcher"
  }

  depends_on = [aws_s3_bucket.reference_bucket, aws_cloudwatch_log_group.batch_log_group]

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_cloudwatch_log_stream" "lambda_watcher" {
  name           = "lambda_watcher"
  log_group_name = aws_cloudwatch_log_group.batch_log_group.name

  depends_on = [aws_cloudwatch_log_group.batch_log_group]
  
}

resource "aws_s3_bucket_notification" "bucket_notifications" {
  bucket = aws_s3_bucket.reference_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_watcher.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_reference_bucket_lambda_watcher,aws_s3_object.reference_data]

}

resource "aws_s3_bucket" "glue_script_bucket" {
  bucket = var.glue_script_bucket

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_glue_job" "glue_batch_processing_job" {
  name     = "${var.glue_script_filename}"
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"
  worker_type = "G.1X"
  number_of_workers = 2
  
  

  command {
    script_location = "s3://${aws_s3_bucket.glue_script_bucket.bucket}/Scripts/${var.glue_script_filename}.py"
    python_version = "3"
  }

  default_arguments = {
    "--enable-metrics" = "true",
    "--enable-spark-ui" = "true",
    "--spark-event-logs-path" = 	"s3://${aws_s3_bucket.glue_script_bucket.bucket}/sparkHistoryLogs/",
    "--enable-job-insights" =	"false",
    "--enable-observability-metrics" =	"true",
    "--enable-glue-datacatalog" =	"true",
    "--enable-continuous-cloudwatch-log" =	"true",
    "--continuous-log-logGroup" = "${aws_cloudwatch_log_group.batch_log_group.name}/${var.glue_script_filename}",
    "--job-bookmark-option" = "job-bookmark-enable",
    "--TempDir"	= "s3://${aws_s3_bucket.glue_script_bucket.bucket}/temporary/",
    "--enable-auto-scaling" =	"true",
    "--job-language" = "python",

    "--TRIGGER" = "NO",
    "--version_tag" = "latest",
    "--processed_bucket_name" = "${var.processed_zone_bucket_name}"
  }
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.glue_script_bucket.id
  key    = "Scripts/${var.glue_script_filename}.py"
  source = "../templates/glue_scripts/${var.glue_script_filename}.py"

  depends_on = [aws_s3_bucket.glue_script_bucket]
}


resource "aws_s3_bucket" "raw_zone_bucket" {
  bucket = var.raw_zone_bucket_name

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_s3_bucket" "processed_zone_bucket" {
  bucket = var.processed_zone_bucket_name

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_s3_bucket" "athena_query_location" {
  bucket = var.athena_query_bucket_name

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}


resource "aws_athena_workgroup" "athena_workgroup" {
  name = var.athena_workgroup_name

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_location.bucket}/"
    }
  }

  depends_on = [ aws_s3_bucket.athena_query_location ]

  tags = {
    app = "RTAD"
    module = "batch module"
  }

}

resource "aws_glue_catalog_database" "data_catalog" {
  name = var.glue_catalog_name

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_glue_catalog_table" "firehose_glue_catalog_table" {
  name          = var.firehose_data_catalog_table_name
  database_name = aws_glue_catalog_database.data_catalog.name

  dynamic "partition_keys" {
    for_each = local.firehose_glue_catalog_table_definition.partitionKeys
      content {
        name = partition_keys.value.name
        type = partition_keys.value.type
      }
  }

  storage_descriptor {

    dynamic "columns" {

      for_each = local.firehose_glue_catalog_table_definition.attributes
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }

    location      = "s3://${aws_s3_bucket.raw_zone_bucket.bucket}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "JsonSerDe"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters            = { "paths" = "patient_id, hearth_rate, sensor_read_timestamp" }

    }
  }


  depends_on = [ aws_glue_catalog_database.data_catalog ]

}

resource "aws_glue_crawler" "raw_zone_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = var.raw_zone_crawler_name
  role          = aws_iam_role.glue_role.arn
  # table_prefix  = aws_glue_catalog_table.firehose_glue_catalog_table.name
  schedule = "cron(0 23 ? * * *)"

  s3_target {
    path = "s3://${aws_s3_bucket.raw_zone_bucket.bucket}"
  }

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_glue_crawler" "processed_zone_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = var.processed_zone_crawler_name
  role          = aws_iam_role.glue_role.arn
  schedule = "cron(0 23 ? * * *)"

  s3_target {
    path = "s3://${aws_s3_bucket.processed_zone_bucket.bucket}"
  }

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_glue_crawler" "reference_bucket_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = var.reference_bucket_crawler_name
  role          = aws_iam_role.glue_role.arn
  schedule = "cron(0 23 ? * * *)"

  s3_target {
    path = "s3://${aws_s3_bucket.reference_bucket.bucket}"
  }

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}


resource "aws_cloudwatch_log_group" "batch_log_group" {
  name = "/RTAD/batch"

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}