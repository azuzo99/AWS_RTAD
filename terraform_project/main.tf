provider "aws" {
  region = "eu-central-1"
}

module "sensors" {

    source = "./modules/sensors_module"
    
    username_1 = var.root_username_1
    password_1 = var.root_password_1
    sensor_1 = var.root_sensor_1

    username_2 = var.root_username_2
    password_2 = var.root_password_2
    sensor_2 = var.root_sensor_2

}


module "streaming" {

    source = "./modules/streaming_module"
    
    kds_stream_name = var.root_kds_stream_name
    flink_app_name =  var.root_flink_app_name

}


module "batch" {

    source = "./modules/batch_module"
    
    reference_bucket_name = var.root_reference_bucket_name
    reference_data_filename = var.root_reference_data_filename

}