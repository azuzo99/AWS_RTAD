output "sensor_1_url" {
  value = aws_cloudformation_stack.sensor_1.outputs["KinesisDataGeneratorUrl"]
}

output "sensor_1_bucket" {
  value = aws_cloudformation_stack.sensor_1.outputs["StagingBucketName"]
}

output "sensor_2_url" {
  value = aws_cloudformation_stack.sensor_2.outputs["KinesisDataGeneratorUrl"]
}


output "sensor_2_bucket" {
  value = aws_cloudformation_stack.sensor_2.outputs["StagingBucketName"]
}