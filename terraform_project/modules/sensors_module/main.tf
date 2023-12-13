resource "aws_cloudformation_stack" "sensor_1" {
  name         = "Sensor1"
  template_body = file("../templates/CloudFormation/sensor_template.yaml")

  parameters = {
    "Username" = var.username_1
    "Password" = var.password_1
    "SensorNumber" = var.sensor_1
  }

  capabilities = ["CAPABILITY_IAM"]

  tags = {
    app = "RTAD"
    module = "sensors module"
  }


}

resource "aws_cloudformation_stack" "sensor_2" {
  name         = "Sensor2"
  template_body = file("../templates/CloudFormation/sensor_template.yaml")

  parameters = {
    "Username" = var.username_2
    "Password" = var.password_2
    "SensorNumber" = var.sensor_2
  }

  capabilities = ["CAPABILITY_IAM"]

    tags = {
      app = "RTAD"
      module = "sensors module"
  }

}