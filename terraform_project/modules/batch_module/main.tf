resource "aws_s3_bucket" "reference_bucket" {
  bucket = var.reference_bucket_name

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_s3_object" "reference_data" {
  bucket = aws_s3_bucket.reference_bucket.id
  key    = var.reference_data_filename
  source = "../templates/S3_Buckets_objects/reference_data/${var.reference_data_filename}"

  depends_on = [aws_s3_bucket.reference_bucket]
}

resource "aws_s3_bucket" "glue_script_bucket" {
  bucket = var.glue_script_bucket

  force_destroy = true

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.glue_script_bucket.id
  key    = var.glue_script_filename
  source = "../templates/S3_Buckets_objects/glue_scripts/${var.glue_script_filename}"

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
  database_name = var.glue_catalog_name

  storage_descriptor {

    columns {
      name = "hearth_rate"
      type = "int"
    }

    columns {
      name = "sensor_read_timestamp"
      type = "timestamp"
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

  partition_keys {
    name = "patient_id"
    type = "int"
  }

}

resource "aws_glue_crawler" "raw_zone_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = var.raw_zone_crawler_name
  role          = aws_iam_role.glue_crawler_role.arn
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
  role          = aws_iam_role.glue_crawler_role.arn
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
  role          = aws_iam_role.glue_crawler_role.arn
  schedule = "cron(0 23 ? * * *)"

  s3_target {
    path = "s3://${aws_s3_bucket.reference_bucket.bucket}"
  }

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}