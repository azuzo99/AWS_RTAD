provider "aws" {
  region = var.region
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

    raw_zone_bucket_name = var.root_raw_zone_bucket_name

    processed_zone_bucket_name = var.root_processed_zone_bucket_name

    athena_query_bucket_name = var.root_athena_query_bucket_name
    athena_workgroup_name = var.root_athena_workgroup_name
    
    glue_catalog_name = var.root_glue_catalog_name
    firehose_data_catalog_table_name = var.root_firehose_data_catalog_table_name

    glue_script_bucket = var.root_glue_script_bucket
    glue_script_filename = var.root_glue_script_filename

    raw_zone_crawler_name = var.root_raw_zone_crawler_name
    processed_zone_crawler_name = var.root_processed_zone_crawler_name
    reference_bucket_crawler_name = var.root_reference_bucket_crawler_name

}