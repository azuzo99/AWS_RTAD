data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  firehose_glue_catalog_table_definition = jsondecode(file("../templates/FirehoseStreamDefinitions/glue_table_definition.json"))
}