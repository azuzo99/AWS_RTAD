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



resource "aws_glue_catalog_database" "data_catalog" {
  name = var.glue_catalog_name

  tags = {
    app = "RTAD"
    module = "batch module"
  }
}

