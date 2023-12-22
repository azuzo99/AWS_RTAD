resource "aws_kinesis_stream" "kds_stream" {
  name             = var.kds_stream_name
  shard_count      = 1
  retention_period = 24


  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    app = "RTAD"
    module = "streaming module"
  }
}


resource "aws_kinesis_firehose_delivery_stream" "firehose_delivery_stream" {
  name        = var.kdf_delivery_stream_name
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kds_stream.arn
    role_arn = aws_iam_role.kinesis_firehose_role.arn
    
  }

  destination = "extended_s3"
  extended_s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_role.arn

    bucket_arn = var.raw_zone_bucket_arn 

    buffering_size = 64        # MiB dla testow mala wartosc, potem ustawic na maxa
    buffering_interval = 60   # s dla testow mala wartosc, potem ustawic na maxa

    # Dynamic Partitioning
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix              = local.firehose_stream_config.dynamic_partitioning_prefix
    error_output_prefix = local.firehose_stream_config.dynamic_partitioning_error_prefix

    cloudwatch_logging_options {
      enabled = "true"
      log_group_name = aws_cloudwatch_log_group.streaming_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    } 

    processing_configuration {
      enabled = "true"


      # Delimiter
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = local.firehose_stream_config.jq_expression
        }
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.glue_data_catalog_name
        role_arn      = aws_iam_role.kinesis_firehose_role.arn
        table_name    = var.firehose_glue_catalog_table_name
      }
    }
  }


  depends_on = [ aws_iam_role_policy_attachment.firehose_stream_attach, aws_cloudwatch_log_group.streaming_log_group ]

  tags = {
    app = "RTAD"
    module = "streaming module"
  }
}


resource "aws_cloudwatch_log_group" "streaming_log_group" {
  name = "/RTAD/streaming"

  tags = {
    app = "RTAD"
    module = "streaming module"
  }
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = var.kdf_delivery_stream_name
  log_group_name = aws_cloudwatch_log_group.streaming_log_group.name

}
