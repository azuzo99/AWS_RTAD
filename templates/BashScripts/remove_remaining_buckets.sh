#!/bin/bash

buckets=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'sensor-') && contains(Name, '-data-storage')].Name" --output text)

for bucket in $buckets; do
  echo "Deleting bucket $bucket"
  aws s3 rb "s3://$bucket" --force
  echo -e "$bucket successfully deleted \n"
done
