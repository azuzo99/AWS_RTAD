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