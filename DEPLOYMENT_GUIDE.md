# Detailed Deployment Guide

Complete step-by-step guide for deploying the ECS S3 Mount infrastructure.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Deployment Steps](#deployment-steps)
4. [Verification](#verification)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
```bash
# Check Terraform version (>= 1.0 required)
terraform version

# Check AWS CLI version
aws --version

# Verify AWS credentials
aws sts get-caller-identity
```

### AWS Permissions Required
Your AWS user/role needs permissions for:
- EC2 (instances, security groups, VPC)
- ECS (clusters, tasks, services)
- IAM (roles, policies, instance profiles)
- S3 (buckets, objects)
- Auto Scaling (groups, launch templates)
- CloudWatch (log groups, logs)
- Systems Manager (Session Manager)

### Network Requirements
- Internet connectivity for downloading mount-s3
- Access to AWS service endpoints (S3, ECS, SSM, CloudWatch)

---

## Initial Setup

### 1. Clone or Download Project

```bash
# If using git
git clone <repository-url>
cd ecs-s3-mount-terraform

# Or download and extract the project files
```

### 2. Configure AWS Credentials

```bash
# Option 1: Using AWS CLI configure
aws configure

# Option 2: Using environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Option 3: Using AWS profile
export AWS_PROFILE="your-profile-name"
```

### 3. Customize Configuration

```bash
cd terraform

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

**terraform.tfvars example:**
```hcl
aws_region   = "us-west-2"
project_name = "my-ecs-s3-project"
bucket_name  = "my-unique-bucket-name"
```

> **Note**: The bucket name will have a random suffix added automatically to ensure uniqueness.

---

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 2: Review Planned Changes

```bash
terraform plan
```

This will show you:
- Resources to be created (VPC, subnets, EC2 instances, ECS cluster, etc.)
- IAM roles and policies
- S3 bucket configuration
- Estimated costs (if using cost estimation tools)

**Review carefully:**
- Number of resources: ~30-40 resources
- Instance types and counts
- Network configuration
- IAM permissions

### Step 3: Apply Configuration

```bash
terraform apply
```

**Interactive prompts:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

**Deployment time:** Approximately 5-10 minutes

**Progress indicators:**
```
aws_vpc.main: Creating...
aws_s3_bucket.test_bucket: Creating...
aws_iam_role.ecs_instance_role: Creating...
...
aws_ecs_service.s3_mount_service: Creation complete after 2m30s

Apply complete! Resources: 35 added, 0 changed, 0 destroyed.
```

### Step 4: Save Outputs

```bash
# View all outputs
terraform output

# Save specific outputs
terraform output cluster_name
terraform output bucket_name
terraform output asg_name
```

**Example outputs:**
```
cluster_name = "ecs-s3-mount-cluster"
bucket_name = "ecs-s3-test-bucket-a1b2c3d4"
asg_name = "ecs-s3-mount-asg"
vpc_id = "vpc-0123456789abcdef0"
```

---

## Verification

### 1. Verify Infrastructure Components

#### Check VPC and Networking
```bash
# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id)

# Verify VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# Verify Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID"
```

#### Check Auto Scaling Group
```bash
# Get ASG name
ASG_NAME=$(terraform output -raw asg_name)

# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME

# List instances in ASG
aws autoscaling describe-auto-scaling-instances \
  --query "AutoScalingInstances[?AutoScalingGroupName=='$ASG_NAME']"
```

#### Check ECS Cluster
```bash
# Get cluster name
CLUSTER_NAME=$(terraform output -raw cluster_name)

# Verify cluster
aws ecs describe-clusters --clusters $CLUSTER_NAME

# List container instances
aws ecs list-container-instances --cluster $CLUSTER_NAME

# Check registered instances
aws ecs describe-container-instances \
  --cluster $CLUSTER_NAME \
  --container-instances $(aws ecs list-container-instances --cluster $CLUSTER_NAME --query 'containerInstanceArns[0]' --output text)
```

#### Check S3 Bucket
```bash
# Get bucket name
BUCKET_NAME=$(terraform output -raw bucket_name)

# Verify bucket exists
aws s3 ls s3://$BUCKET_NAME

# Check test files
aws s3 ls s3://$BUCKET_NAME/test-data/
```

### 2. Verify ECS Tasks

```bash
# List running tasks
aws ecs list-tasks --cluster $CLUSTER_NAME

# Get task details
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN
```

### 3. Check CloudWatch Logs

```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /ecs/ecs-s3-mount \
  --order-by LastEventTime \
  --descending

# Tail logs
aws logs tail /ecs/ecs-s3-mount --follow

# Get specific log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name /ecs/ecs-s3-mount \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

aws logs get-log-events \
  --log-group-name /ecs/ecs-s3-mount \
  --log-stream-name $LOG_STREAM
```

**Expected log output:**
```
Starting S3 mount test...
total 0
drwxr-xr-x 3 root root 0 Nov 10 12:00 test-data
Contents of test-data directory:
-rw-r--r-- 1 root root 123 Nov 10 12:00 sample.txt
-rw-r--r-- 1 root root 456 Nov 10 12:00 config.json
Reading sample.txt:
Hello from S3! This is a test file for ECS S3 mount.
S3 mount test completed successfully!
```

### 4. Connect to Instance via SSM

```bash
# Get instance ID
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# Start SSM session
aws ssm start-session --target $INSTANCE_ID
```

**Once connected, verify S3 mount:**
```bash
# Check mount point
mountpoint /mnt/s3-bucket

# List contents
ls -la /mnt/s3-bucket

# Read test file
cat /mnt/s3-bucket/test-data/sample.txt

# Check mount options
mount | grep s3-bucket

# View mount logs
sudo cat /var/log/s3-mount.log

# Check user data execution
sudo cat /var/log/user-data.log
```

---

## Post-Deployment Configuration

### 1. Upload Additional Files to S3

```bash
# Upload a file
aws s3 cp myfile.txt s3://$BUCKET_NAME/myfile.txt

# Upload a directory
aws s3 sync ./local-directory s3://$BUCKET_NAME/remote-directory/

# Verify upload
aws s3 ls s3://$BUCKET_NAME/ --recursive
```

### 2. Scale the Auto Scaling Group

```bash
# Scale up to 3 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 3

# Wait for instances to launch
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]'

# Scale down to 1 instance
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 1
```

### 3. Update ECS Service

```bash
# Increase task count
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service ecs-s3-mount-service \
  --desired-count 2

# Force new deployment
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service ecs-s3-mount-service \
  --force-new-deployment
```

### 4. Configure Auto Scaling Policies (Optional)

Create a target tracking scaling policy:

```bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name cpu-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 70.0
  }'
```

---

## Troubleshooting

### Issue: ECS Instance Not Registering

**Symptoms:**
- No container instances in ECS cluster
- ASG shows instances running but ECS shows 0 instances

**Diagnosis:**
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID

# Connect via SSM
aws ssm start-session --target $INSTANCE_ID

# Check ECS agent
sudo systemctl status ecs
sudo cat /var/log/ecs/ecs-agent.log

# Check ECS config
sudo cat /etc/ecs/ecs.config
```

**Solutions:**
1. Verify IAM instance profile is attached
2. Check ECS agent is running: `sudo systemctl restart ecs`
3. Verify cluster name in `/etc/ecs/ecs.config`
4. Check network connectivity to ECS endpoints

### Issue: S3 Mount Fails

**Symptoms:**
- Container cannot access `/app/s3-data`
- Mount point is empty

**Diagnosis:**
```bash
# Connect to instance
aws ssm start-session --target $INSTANCE_ID

# Check mount status
mountpoint /mnt/s3-bucket
mount | grep s3-bucket

# Check mount-s3 installation
which mount-s3
mount-s3 --version

# View mount logs
sudo cat /var/log/s3-mount.log
sudo cat /var/log/user-data.log
```

**Solutions:**
1. Verify IAM permissions for S3 access
2. Check mount-s3 is installed: `sudo yum install -y /tmp/mount-s3.rpm`
3. Manually mount: `sudo mount-s3 $BUCKET_NAME /mnt/s3-bucket --allow-other`
4. Check bucket exists: `aws s3 ls s3://$BUCKET_NAME`

### Issue: Cannot Connect via SSM

**Symptoms:**
- `aws ssm start-session` fails
- Instance not showing in Session Manager

**Diagnosis:**
```bash
# Check SSM agent status (if you can access instance another way)
sudo systemctl status amazon-ssm-agent

# Check IAM role
aws iam get-role --role-name ecs-s3-mount-ecs-instance-role
aws iam list-attached-role-policies --role-name ecs-s3-mount-ecs-instance-role
```

**Solutions:**
1. Verify SSM policy is attached to instance role
2. Check instance has internet connectivity
3. Restart SSM agent: `sudo systemctl restart amazon-ssm-agent`
4. Wait 5-10 minutes for agent to register

### Issue: Task Fails to Start

**Symptoms:**
- Task status shows STOPPED
- Service cannot maintain desired count

**Diagnosis:**
```bash
# Get stopped task details
STOPPED_TASK=$(aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status STOPPED --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $STOPPED_TASK

# Check service events
aws ecs describe-services --cluster $CLUSTER_NAME --services ecs-s3-mount-service --query 'services[0].events'
```

**Solutions:**
1. Check task definition is valid
2. Verify container image is accessible
3. Ensure sufficient resources (CPU/memory) on instance
4. Check mount point exists on host: `/mnt/s3-bucket`

### Issue: High Costs

**Diagnosis:**
```bash
# Check running resources
terraform state list

# Check instance types
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecs-s3-mount" --query 'Reservations[].Instances[].[InstanceType,State.Name]'
```

**Solutions:**
1. Scale down ASG: `aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 1`
2. Use smaller instance type (edit `terraform/asg.tf`)
3. Stop ECS service: `aws ecs update-service --cluster $CLUSTER_NAME --service ecs-s3-mount-service --desired-count 0`
4. Destroy infrastructure when not needed: `terraform destroy`

---

## Cleanup

### Complete Cleanup

```bash
cd terraform
terraform destroy
```

**Confirm destruction:**
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

### Partial Cleanup

**Stop ECS tasks but keep infrastructure:**
```bash
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service ecs-s3-mount-service \
  --desired-count 0
```

**Scale down ASG:**
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 0
```

### Verify Cleanup

```bash
# Check for remaining resources
aws ecs list-clusters
aws autoscaling describe-auto-scaling-groups
aws s3 ls | grep ecs-s3

# Check Terraform state
terraform state list
```

---

## Next Steps

1. **Customize the application**: Modify the container definition in `terraform/ecs.tf`
2. **Add monitoring**: Set up CloudWatch alarms and dashboards
3. **Implement CI/CD**: Automate deployments with GitHub Actions or AWS CodePipeline
4. **Enhance security**: Implement VPC endpoints, private subnets, and stricter IAM policies
5. **Add load balancing**: Integrate Application Load Balancer for web applications
6. **Configure backups**: Set up S3 lifecycle policies and versioning

---

## Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Mountpoint for S3 Documentation](https://github.com/awslabs/mountpoint-s3/blob/main/doc/CONFIGURATION.md)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)

---

**Last Updated:** November 2025
