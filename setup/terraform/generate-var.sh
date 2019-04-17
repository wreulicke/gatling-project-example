#!/bin/bash
if [ -e $AWS_PROFILE ]; then
    echo "Cannot get profile"
    exit 1
fi

BUCKET_NAME=$(aws s3api list-buckets | jq '.Buckets[] | select(.Name | startswith("load-test-state")) | .Name')
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)
IMAGE_ID=$(aws ec2 describe-images --owners $ACCOUNT_ID --filter "Name=tag:Name,Values=load-test" | jq .Images[0].ImageId)
MY_IP=`curl -s ifconfig.co`

cat << EOF 
backend_bucket = $BUCKET_NAME
profile = "$AWS_PROFILE"
load_test_ami = $IMAGE_ID
key_name = "${AWS_PROFILE}"
my_ip = "$MY_IP"
instance_size = "m4.large"
EOF