import sys
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.job import Job
from awsglue.transforms import Join
from pyspark.sql.functions import input_file_name, regexp_extract
import logging


## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'VERSION_TAG', 'PROCESSED_BUCKET_NAME','RAW_BUCKET_NAME','REFERENCE_BUCKET_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
job = Job(glueContext)
job.init(args.get('JOB_NAME'), args)


logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


## Load reference data
reference_read_base_options = {
    "connection_type": "s3",
    "connection_options": {
        "paths": [f"s3://{args.get('REFERENCE_BUCKET_NAME')}"]
    },
    "format": "csv",
    "format_options": {
        "withHeader": True
    },
    "transformation_ctx": "read_reference_dataset"
}

if args.get('VERSION_TAG') not in ('latest',''):
    reference_read_base_options["connection_options"]["versionId"] = args.get('VERSION_TAG')
    

s3_reference_data = glueContext.create_dynamic_frame.from_options(**reference_read_base_options)
logger.info("Reference Data Schema:")
logger.info(s3_reference_data.printSchema())

# Load raw data
s3_raw_data = glueContext.create_dynamic_frame.from_options(
                connection_type="s3",
                connection_options={
                    "paths": [f"s3://{args.get('RAW_BUCKET_NAME')}"],
                    "recurse": True,
                    "groupFiles": "inPartition",
                    "groupSize": "1048576",
                     "partitionKeys": ["date", "holter_id"]
                },
                format="parquet",
                transformation_ctx="read_raw_dataset",
                additional_options={"jobBookmarkKeys": ["sensor_read_timestamp"], "jobBookmarkKeysSortOrder": "asc"}
            )


s3_raw_data_staging = s3_raw_data.toDF() \
                    .withColumn("data_origin", input_file_name()) \
                    .withColumn("processing_date", regexp_extract("data_origin", "date=(\\d{4}-\\d{2}-\\d{2})", 1)) \
                    .withColumn("holter_id", regexp_extract("data_origin", "holter_id=(\\d+)", 1))

s3_raw_data_transformed = DynamicFrame.fromDF(s3_raw_data_staging, glueContext, "s3_raw_data_staging creation")

logger.info("Transformed Data Schema:")
logger.info(s3_raw_data_transformed.printSchema())

#data join and bookmarks enabled
processed_data = Join.apply(
    s3_reference_data,
    s3_raw_data_transformed,
    'holter_id',
    'holter_id',
    transformation_ctx="raw and reference merge"
)
logger.info("Processed Data Schema:")
logger.info(processed_data.printSchema())

# Unload the data to the "processed" bucket
glueContext.write_dynamic_frame.from_options(
    frame=processed_data,
    connection_type="s3",
    connection_options={
        "path": f"s3://{args.get('PROCESSED_BUCKET_NAME')}",
        "partitionKeys": ["patient_id", "processing_date"]
    },
    format="csv",
    format_options={
        "separator": ",",
        "writeHeader": True
    },
    transformation_ctx="processed data unload"
)

job.commit()
