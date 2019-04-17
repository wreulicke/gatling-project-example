#!/bin/bash
# Note: 
# Required AWS_PROFILE envvar or default profile.

set -e
THIS_SHELL_PATH=$(dirname $0)
AMI_ID=`aws ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2' 'Name=state,Values=available' --output json \
    | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'`
if [ -z $AMI_ID ]; then
    echo "Cannot resolve AMI ID for Amazon Linux 2. Terminate to create load testing image..."
    exit 1
fi

GIT_ROOT=`git rev-parse --show-cdup`
packer build -var "source_ami=$AMI_ID" -var "git_root=$GIT_ROOT" $THIS_SHELL_PATH/packer.json
