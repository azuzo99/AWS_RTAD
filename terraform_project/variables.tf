# External
variable "region" {
  description = "Region"
  type        = string
}


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

variable "root_kdf_delivery_stream_name" {
  description = "Name of Kinesis Firehose Delivery Stream"
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

variable "root_raw_zone_bucket_name" {
  description = "Name of Raw Zone Bucket"
  type        = string
}

variable "root_processed_zone_bucket_name" {
  description = "Name of Processed Zone Bucket"
  type        = string
}

variable "root_athena_query_bucket_name" {
  description = "Name of Athena Query Bucket"
  type        = string
}

variable "root_athena_workgroup_name" {
  description = "Name of Athena Workgroup"
  type        = string
}

variable "root_glue_catalog_name" {
  description = "Name of Glue Data Catalog"
  type        = string
}

variable "root_firehose_data_catalog_table_name" {
  description = "Name of Firehose Data Catalog Table"
  type        = string
}


variable "root_glue_script_bucket" {
  description = "Name of Glue Script Bucket Location"
  type        = string
}

variable "root_glue_script_filename" {
  description = "Name of Glue Script File"
  type        = string
}

variable "root_raw_zone_crawler_name" {
  description = "Name of Raw Zone Crawler"
  type        = string
}
variable "root_processed_zone_crawler_name" {
  description = "Name of Processed Zone Crawler"
  type        = string
}

variable "root_reference_bucket_crawler_name" {
  description = "Name of Reference Bucket Crawler"
  type        = string
}

