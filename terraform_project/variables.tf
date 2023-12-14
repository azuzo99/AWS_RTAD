# Sensor Module
variable "root_username_1" {
  description = "Username for the first sensor"
  type        = string
}

variable "root_password_1" {
  description = "Password for the first sensor"
  type        = string
}

variable "root_sensor_1" {
  description = "A no. of sensor"
  type        = number
}

variable "root_username_2" {
  description = "Username for second sensor"
  type        = string
}

variable "root_password_2" {
  description = "Password for the second sensor"
  type        = string
}

variable "root_sensor_2" {
  description = "A no. of sensor"
  type        = number
}

# Streaming Module 
variable "root_kds_stream_name" {
  description = "Name of the Kinesis Data Streams"
  type        = string
}

variable "root_flink_app_name" {
  description = "Name of Flink app"
  type        = string
}


# Batch Module
variable "root_reference_bucket_name" {
  description = "Name of Reference Bucket"
  type        = string
}

variable "root_reference_data_filename" {  
  description = "Name of Reference Data Filename"
  type        = string
}