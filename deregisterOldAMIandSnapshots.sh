#!/bin/bash
##  Purpose: In AWS Deregister OLD AMIs and their Snapshots
##  Usage: sh deregisterOldAMIandSnapshots.sh
##          Deregister AMI and its snapshot as per date configured in scripts.

## Variable declarations
v_owner=333803208799
v_region=us-east-1

input=`echo $1 | awk '{print tolower($0)}'`
if [ "$input" == "help" ]; then
  echo "Usage:: sh deregisterOldAMIandSnapshots.sh"
  echo "           Deregister AMI and its snapshot as per date configured in scripts."
  exit 0
fi

#if date -v-30d > /dev/null 2>&1; then
    # BSD systems (Mac OS X)
#    DATE=date -v-30d +%Y-%m-%d
#else
    # GNU systems (Linux)
#    DATE=date --date="-30 days" +%Y-%m-%d
#fi

#--filters "Name=tag:Name,Values=Test"  \
v_array_ami=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
 --query 'Images[?CreationDate<=`2020-09-30`].ImageId' \
 --output text))

v_array_ami_lenght=${#v_array_ami[@]}

if [ $v_array_ami_lenght -eq 0 ]; then
  echo "No AMI to degister.. Done nothing.."
fi

for (( i=0; i<v_array_ami_lenght; i++ ))
do
  temp_ami_id=${v_array_ami[$i]}
  # --filters "Name=tag:Name,Values=Test" \
  #    --query 'Images[?CreationDate<=`2019-09-30`].BlockDeviceMappings[*].Ebs.SnapshotId' \
  v_array_snapshot=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
   --image-ids $temp_ami_id \
   --output text \
   --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId'))

  v_array_snapshot_lenght=${#v_array_snapshot[@]}
  
 v_creationdate=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
   --image-ids $temp_ami_id \
   --output text \
   --query 'Images[*].CreationDate'))

  echo "Deregistering AMI: $temp_ami_id, created on $v_creationdate"
  aws ec2 deregister-image --image-id $temp_ami_id --region $v_region

  echo "  Removing Snapshots.."

  for (( j=0; j<$v_array_snapshot_lenght; j++ ))
  do
    temp_snapshot_id=${v_array_snapshot[$j]}
    echo "  Deleting Snapshot: $temp_snapshot_id"
    aws ec2 delete-snapshot --snapshot-id $temp_snapshot_id --region $v_region
  done
done

exit 0