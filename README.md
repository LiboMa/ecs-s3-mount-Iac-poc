# ECS S3 Mount with Auto Scaling - Terraform Project

A production-ready infrastructure-as-code solution for mounting S3 buckets to ECS containers running on EC2 instances managed by Auto Scaling Groups.

## 🎯 Project Overview

This project demonstrates how to:
- Mount S3 buckets directly to ECS containers using Mountpoint for Amazon S3
- Deploy ECS clusters with Auto Scaling Groups for high availability
- Manage infrastructure using Terraform with best practices
- Configure proper IAM permissions for secure S3 access
- Enable Systems Manager (SSM) for secure instance access

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                   │ │
│  │                                                         │ │
│  │  ┌──────────────────┐      ┌──────────────────┐       │ │
│  │  │  Public Subnet 1 │      │  Public Subnet 2 │       │ │
│  │  │  10.0.1.0/24     │      │  10.0.2.0/24     │       │ │
│  │  │                  │      │                  │       │ │
│  │  │  ┌────────────┐  │      │  ┌────────────┐  │       │ │
│  │  │  │ EC2 (ASG)  │  │      │  │ EC2 (ASG)  │  │       │ │
│  │  │  │ t3.xlarge  │  │      │  │ t3.xlarge  │  │       │ │
│  │  │  │            │  │      │  │            │  │       │ │
│  │  │  │ ┌────────┐ │  │      │  │ ┌────────┐ │  │       │ │
│  │  │  │ │  ECS   │ │  │      │  │ │  ECS   │ │  │       │ │
│  │  │  │ │ Task   │ │  │      │  │ │ Task   │ │  │       │ │
│  │  │  │ │        │ │  │      │  │ │        │ │  │       │ │
│  │  │  │ │ /app/  │ │  │      │  │ │ /app/  │ │  │       │ │
│  │  │  │ │s3-data │ │  │      │  │ │s3-data │ │  │       │ │
│  │  │  │ └────┬───┘ │  │      │  │ └────┬───┘ │  │       │ │
│  │  │  │      │     │  │      │  │      │     │  │       │ │
│  │  │  │ /mnt/s3-bucket │      │  │ /mnt/s3-bucket │       │ │
│  │  │  │   (mount-s3)   │      │  │   (mount-s3)   │       │ │
│  │  │  └──────┼─────┘  │      │  └──────┼─────┘  │       │ │
│  │  └─────────┼────────┘      └─────────┼────────┘       │ │
│  │            │                          │                │ │
│  └────────────┼──────────────────────────┼────────────────┘ │
│               │                          │                  │
│               └──────────┬───────────────┘                  │
│                          │                                  │
│                    ┌─────▼─────┐                            │
│                    │ S3 Bucket │                            │
│                    │  (Files)  │                            │
│                    └───────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

## ✨ Features

- **Auto Scaling**: Automatic scaling based on demand (1-3 instances)
- **High Availability**: Multi-AZ deployment across 2 availability zones
- **S3 Integration**: Direct S3 bucket mounting using Mountpoint for Amazon S3
- **Secure Access**: SSM Session Manager for secure instance access (no SSH keys needed)
- **Full Permissions**: Complete S3, KMS, and SSM access for instances
- **Monitoring**: CloudWatch Logs integration for container logs
- **Infrastructure as Code**: Complete Terraform configuration
- **Production Ready**: Proper error handling, logging, and validation

## 📋 Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured with credentials
- Basic understanding of ECS, S3, and Terraform

## 🚀 Quick Start

### 1. Clone and Configure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:
```hcl
aws_region   = "us-west-2"
project_name = "ecs-s3-mount"
bucket_name  = "my-ecs-s3-bucket"
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify Deployment

```bash
# Check ECS cluster
aws ecs list-container-instances --cluster ecs-s3-mount-cluster

# Check running tasks
aws ecs list-tasks --cluster ecs-s3-mount-cluster

# View container logs
aws logs tail /ecs/ecs-s3-mount --follow
```

### 4. Access Instance via SSM

```bash
# List instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecs-s3-mount" --query "Reservations[].Instances[].InstanceId"

# Connect via Session Manager
aws ssm start-session --target <instance-id>

# Verify S3 mount
ls -la /mnt/s3-bucket
```

## 📁 Project Structure

```
.
├── terraform/
│   ├── main.tf              # Main configuration and variables
│   ├── vpc.tf               # VPC, subnets, and networking
│   ├── iam.tf               # IAM roles and policies
│   ├── s3.tf                # S3 bucket configuration
│   ├── asg.tf               # Auto Scaling Group and Launch Template
│   ├── ecs.tf               # ECS cluster, task definition, and service
│   ├── outputs.tf           # Output values
│   ├── user_data.sh         # EC2 initialization script
│   └── terraform.tfvars.example
├── scripts/
│   └── userdata.sh          # Additional scripts
├── README.md                # This file
└── DEPLOYMENT_GUIDE.md      # Detailed deployment guide
```

## 🔧 Configuration Details

### Instance Configuration
- **Type**: t3.xlarge (4 vCPU, 16 GB RAM)
- **AMI**: Latest ECS-optimized Amazon Linux 2
- **Storage**: Default EBS volume
- **Networking**: Public subnets with Internet Gateway

### IAM Permissions
The ECS instance role includes:
- **ECS**: Full container service permissions
- **S3**: Full access to all S3 operations
- **SSM**: Complete Systems Manager access
- **KMS**: Full key management permissions
- **CloudWatch**: Log writing permissions

### S3 Mount Configuration
- **Tool**: Mountpoint for Amazon S3 (mount-s3)
- **Mount Point**: `/mnt/s3-bucket` on host
- **Container Path**: `/app/s3-data` in container
- **Options**: `allow-other`, `rw`, `nofail`
- **Persistence**: Configured in `/etc/fstab`

## 📊 Monitoring and Logs

### CloudWatch Logs
```bash
# View container logs
aws logs tail /ecs/ecs-s3-mount --follow

# View specific log stream
aws logs get-log-events \
  --log-group-name /ecs/ecs-s3-mount \
  --log-stream-name ecs/s3-test-app/<task-id>
```

### Instance Logs
Connect via SSM and check:
```bash
# User data execution log
sudo cat /var/log/user-data.log

# S3 mount status log
sudo cat /var/log/s3-mount.log

# ECS agent log
sudo cat /var/log/ecs/ecs-agent.log
```

## 🔄 Scaling Operations

### Manual Scaling
```bash
# Scale up to 3 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ecs-s3-mount-asg \
  --desired-capacity 3

# Scale down to 1 instance
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ecs-s3-mount-asg \
  --desired-capacity 1
```

### Auto Scaling Policies
You can add auto scaling policies based on:
- CPU utilization
- Memory utilization
- Custom CloudWatch metrics
- Scheduled scaling

## 🧪 Testing

### Test S3 Access
```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# Check mount
mountpoint /mnt/s3-bucket
ls -la /mnt/s3-bucket

# Test read
cat /mnt/s3-bucket/test-data/sample.txt

# Test write
echo "test" > /mnt/s3-bucket/test-file.txt
```

### Test Container Access
The ECS task automatically tests S3 access on startup by:
1. Listing mounted directory contents
2. Reading test files
3. Logging results to CloudWatch

## 🛡️ Security Best Practices

- ✅ IAM roles with least privilege (can be further restricted)
- ✅ VPC with proper network segmentation
- ✅ SSM Session Manager (no SSH keys or open ports)
- ✅ S3 bucket encryption enabled (AES256)
- ✅ S3 bucket versioning enabled
- ✅ CloudWatch logging for audit trails
- ✅ Security groups with minimal required access

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

This will remove:
- ECS cluster and tasks
- Auto Scaling Group and EC2 instances
- S3 bucket and contents
- VPC and networking components
- IAM roles and policies
- CloudWatch log groups

## 📝 Customization

### Change Instance Type
Edit `terraform/asg.tf`:
```hcl
instance_type = "t3.2xlarge"  # 8 vCPU, 32 GB RAM
```

### Adjust Auto Scaling Limits
Edit `terraform/asg.tf`:
```hcl
min_size         = 2
max_size         = 10
desired_capacity = 2
```

### Modify Container Resources
Edit `terraform/ecs.tf`:
```hcl
cpu    = "512"   # 0.5 vCPU
memory = "1024"  # 1 GB
```

## 🐛 Troubleshooting

### S3 Mount Fails
1. Check IAM permissions: `aws iam get-role --role-name ecs-s3-mount-ecs-instance-role`
2. Verify mount-s3 installation: `which mount-s3`
3. Check logs: `cat /var/log/user-data.log`

### ECS Tasks Not Starting
1. Check cluster instances: `aws ecs list-container-instances --cluster <cluster-name>`
2. Verify task definition: `aws ecs describe-task-definition --task-definition <task-name>`
3. Check service events: `aws ecs describe-services --cluster <cluster-name> --services <service-name>`

### Cannot Connect via SSM
1. Verify SSM agent is running: `systemctl status amazon-ssm-agent`
2. Check IAM role has SSM permissions
3. Ensure instance has internet connectivity

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 🔗 Resources

- [Mountpoint for Amazon S3](https://github.com/awslabs/mountpoint-s3)
- [Amazon ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

## 📧 Support

For issues and questions:
- Check the troubleshooting section
- Review CloudWatch logs
- Examine user data execution logs
- Verify IAM permissions

---

**Built with ❤️ using Terraform and AWS**
