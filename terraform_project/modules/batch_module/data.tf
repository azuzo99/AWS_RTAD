data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  firehose_glue_catalog_table_definition = jsondecode(file("../templates/FirehoseStreamDefinitions/glue_table_definition.json"))
}

data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "../templates/Lambda_codes/${var.lambda_code_filename}.py"
  output_path = "../templates/Lambda_codes/${var.lambda_code_filename}.zip"
}