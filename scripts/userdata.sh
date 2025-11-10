#!/bin/bash

echo ECS_CLUSTER=s3-mount-cluster >> /etc/ecs/ecs.config
curl -L https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm -o /tmp/mount-s3.rpm
yum install -y /tmp/mount-s3.rpm
mkdir -p /mnt/s3-bucket
mount-s3 ecs-s3-test-test-bucket-hljs94ih /mnt/s3-bucket
systemctl restart ecs


## to generate the user data

echo """echo ECS_CLUSTER=s3-mount-cluster >> /etc/ecs/ecs.config
curl -L https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm -o /tmp/mount-s3.rpm
yum install -y /tmp/mount-s3.rpm
mkdir -p /mnt/s3-bucket
mount-s3 ecs-s3-test-test-bucket-hljs94ih /mnt/s3-bucket
systemctl restart ecs"""|base64
