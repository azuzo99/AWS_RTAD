import sys
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.job import Job
from datetime import datetime

## @params: [JOB_NAME, TRIGGER]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'TRIGGER', '--version_tag'])

sc = SparkContext()
glueContext = GlueContext(sc)
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

#Trigger resolving and args parsing
if args['TRIGGER']=='yes' and args['version_tag']:
    data = [(args['version_tag'], args['TRIGGER'])]  # Data needs to be in tuple format
elif args['TRIGGER']=='no' and args['version_tag'] == 'latest':
    data = [(args['version_tag'], args['TRIGGER'])]  # Data needs to be in tuple format
else:
    data = [("None", "None")]  # Data needs to be in tuple format

#TODO load from sources
#TODO data join and bookmarks enabled
#TODO partitioning and unload to target

columns = ["version", "value"]  # Column names

# Convert to RDD first, then to DynamicFrame
rdd = sc.parallelize(data)
df = rdd.toDF(columns)
df = df.coalesce(1)
dynamic_frame = DynamicFrame.fromDF(df, glueContext, "dynamic_frame")

# Define your target data path
processed_bucket_path = "s3://glue-lambda-test-output-pass"

# Write DynamicFrame to S3 bucket in JSON format
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    connection_options={"path": processed_bucket_path},
    format="json"
)

job.commit()



