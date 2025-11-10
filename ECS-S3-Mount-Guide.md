# ECS S3 Mount Setup Guide

## Overview
Mount S3 bucket to ECS containers using mount-s3 on EC2 instances.

## Prerequisites
- S3 bucket: `ecs-s3-test-test-bucket-hljs94ih`
- VPC subnet: `subnet-017213b7a972963da`
- Security group: `sg-05774d2b5ac5c9926`

## Step 1: Create IAM Roles

### ECS Task Execution Role
```bash
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### ECS Instance Role
```bash
aws iam create-role --role-name ecsInstanceRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

aws iam attach-role-policy --role-name ecsInstanceRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role

aws iam create-instance-profile --instance-profile-name ecsInstanceProfile
aws iam add-role-to-instance-profile --role-name ecsInstanceRole --instance-profile-name ecsInstanceProfile
```

### S3 Access Role
```bash
aws iam create-role --role-name ecsS3AccessRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

aws iam put-role-policy --role-name ecsS3AccessRole --policy-name S3AccessPolicy --policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"],
    "Resource": ["arn:aws:s3:::ecs-s3-test-test-bucket-hljs94ih", "arn:aws:s3:::ecs-s3-test-test-bucket-hljs94ih/*"]
  }]
}'
```

## Step 2: Create ECS Cluster
```bash
aws ecs create-cluster --cluster-name s3-mount-cluster --region us-west-2
```

## Step 3: Launch EC2 Instance
```bash
aws ec2 run-instances \
  --image-id ami-003b2a6ff6af73efd \
  --instance-type t3.medium \
  --iam-instance-profile Name=ecsInstanceProfile \
  --security-group-ids sg-05774d2b5ac5c9926 \
  --subnet-id subnet-017213b7a972963da \
  --user-data "IyEvYmluL2Jhc2gKZWNobyBFQ1NfQ0xVU1RFUj1zMy1tb3VudC1jbHVzdGVyID4+IC9ldGMvZWNzL2Vjcy5jb25maWcKY3VybCAtTCBodHRwczovL3MzLmFtYXpvbmF3cy5jb20vbW91bnRwb2ludC1zMy1yZWxlYXNlL2xhdGVzdC94ODZfNjQvbW91bnQtczMucnBtIC1vIC90bXAvbW91bnQtczMucnBtCnl1bSBpbnN0YWxsIC15IC90bXAvbW91bnQtczMucnBtCm1rZGlyIC1wIC9tbnQvczMtYnVja2V0Cm1vdW50LXMzIGVjcy1zMy10ZXN0LXRlc3QtYnVja2V0LWhsanM5NGloIC9tbnQvczMtYnVja2V0CnN5c3RlbWN0bCByZXN0YXJ0IGVjcw==" \
  --region us-west-2
```

## Step 4: Create Task Definition
```json
{
  "family": "s3-mount-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["EC2"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsS3AccessRole",
  "containerDefinitions": [{
    "name": "s3-app-container",
    "image": "amazonlinux:2023",
    "essential": true,
    "mountPoints": [{
      "sourceVolume": "s3-volume",
      "containerPath": "/app/s3-data",
      "readOnly": false
    }],
    "command": ["/bin/bash", "-c", "ls -la /app/s3-data && echo 'S3 mounted successfully' && tail -f /dev/null"],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/s3-mount",
        "awslogs-region": "us-west-2",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }],
  "volumes": [{
    "name": "s3-volume",
    "host": {"sourcePath": "/mnt/s3-bucket"}
  }]
}
```

## Step 5: Register and Run Task
```bash
# Create log group
aws logs create-log-group --log-group-name /ecs/s3-mount --region us-west-2

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json --region us-west-2

# Run task
aws ecs run-task \
  --cluster s3-mount-cluster \
  --task-definition s3-mount-task \
  --launch-type EC2 \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-017213b7a972963da],securityGroups=[sg-05774d2b5ac5c9926]}" \
  --region us-west-2
```

## File Monitoring (Optional)
For monitoring new files in S3:
```bash
# In container
yum install -y inotify-tools
inotifywait -m -r -e create,moved_to /app/s3-data --format '%w%f' | 
while read file; do 
  if [[ -f "$file" ]]; then 
    echo "$(date): NEW FILE: $file"
    ls -la "$file"
  fi
done
```

## Key Points
- **Fargate**: Does NOT support privileged containers (required for mount-s3)
- **EC2 Launch Type**: Required for S3 mounting
- **ECS-Optimized AMI**: Use `ami-003b2a6ff6af73efd` for automatic ECS agent
- **Host Mount**: S3 mounted on host at `/mnt/s3-bucket`, bind-mounted to container at `/app/s3-data`
- **Permissions**: Instance role needs S3 access, task role needs S3 access

## Verification
```bash
# Check cluster
aws ecs list-container-instances --cluster s3-mount-cluster --region us-west-2

# Check task
aws ecs list-tasks --cluster s3-mount-cluster --region us-west-2

# View logs
aws logs get-log-events --log-group-name /ecs/s3-mount --log-stream-name ecs/s3-app-container/TASK_ID --region us-west-2
```
