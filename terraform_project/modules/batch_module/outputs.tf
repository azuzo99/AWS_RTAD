output "aws_region" {
  value = data.aws_region.current.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "glue_data_catalog_name" {
  value = aws_glue_catalog_database.data_catalog.name
}

output "firehose_glue_catalog_table_name" {
  value = aws_glue_catalog_table.firehose_glue_catalog_table.name
}

output "raw_zone_bucket_arn" {
  value = aws_s3_bucket.raw_zone_bucket.arn
}
