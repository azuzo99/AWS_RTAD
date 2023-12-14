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