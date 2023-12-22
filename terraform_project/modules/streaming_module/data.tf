locals {
  firehose_stream_config = jsondecode(file("../templates/FirehoseStreamDefinitions/firehose_stream_config.json"))
}