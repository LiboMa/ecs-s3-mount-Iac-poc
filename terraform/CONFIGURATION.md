# Terraform Configuration Guide

This document explains all configurable variables for the ECS S3 Mount infrastructure.

## Quick Start

1. Copy the example configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

---

## Configuration Variables

### AWS Configuration

#### `aws_region`
- **Description**: AWS region where resources will be created
- **Type**: String
- **Default**: `"us-west-2"`
- **Example**: `"us-east-1"`, `"eu-west-1"`, `"ap-southeast-1"`

#### `project_name`
- **Description**: Project name used for resource naming and tagging
- **Type**: String
- **Default**: `"ecs-s3-mount"`
- **Example**: `"my-app"`, `"production-ecs"`

#### `environment`
- **Description**: Environment name for tagging
- **Type**: String
- **Default**: `"test"`
- **Example**: `"dev"`, `"staging"`, `"prod"`

---

### S3 Configuration

#### `bucket_name`
- **Description**: S3 bucket name (random suffix will be added automatically)
- **Type**: String
- **Default**: `"ecs-s3-test-bucket"`
- **Example**: `"my-app-data"`, `"production-storage"`
- **Note**: Final bucket name will be `{bucket_name}-{random-suffix}`

---

### VPC Configuration

#### `vpc_cidr`
- **Description**: CIDR block for the VPC
- **Type**: String
- **Default**: `"10.0.0.0/16"`
- **Valid Range**: Any valid IPv4 CIDR block
- **Examples**:
  - `"10.0.0.0/16"` - 65,536 IP addresses
  - `"172.16.0.0/16"` - 65,536 IP addresses
  - `"192.168.0.0/16"` - 65,536 IP addresses

#### `availability_zones_count`
- **Description**: Number of availability zones to use
- **Type**: Number
- **Default**: `2`
- **Valid Range**: 1-3
- **Recommendation**: Use 2 or 3 for high availability

#### `public_subnet_cidrs`
- **Description**: List of CIDR blocks for public subnets
- **Type**: List of strings
- **Default**: `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`
- **Requirements**: 
  - Must be within VPC CIDR range
  - Must not overlap
  - Provide at least as many as `availability_zones_count`
- **Examples**:
  ```hcl
  # For 2 AZs
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  
  # For 3 AZs with larger subnets
  public_subnet_cidrs = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  ```

#### `enable_dns_hostnames`
- **Description**: Enable DNS hostnames in the VPC
- **Type**: Boolean
- **Default**: `true`
- **Recommendation**: Keep `true` for ECS

#### `enable_dns_support`
- **Description**: Enable DNS support in the VPC
- **Type**: Boolean
- **Default**: `true`
- **Recommendation**: Keep `true` for ECS

#### `map_public_ip_on_launch`
- **Description**: Auto-assign public IP to instances
- **Type**: Boolean
- **Default**: `true`
- **Recommendation**: Keep `true` for public subnets

---

### EC2 Instance Configuration

#### `instance_type`
- **Description**: EC2 instance type for ECS container instances
- **Type**: String
- **Default**: `"t3.xlarge"`
- **Common Options**:

| Instance Type | vCPU | Memory | Use Case |
|--------------|------|--------|----------|
| t3.micro | 2 | 1 GB | Testing only |
| t3.small | 2 | 2 GB | Light workloads |
| t3.medium | 2 | 4 GB | Small applications |
| t3.large | 2 | 8 GB | Medium workloads |
| **t3.xlarge** | **4** | **16 GB** | **Recommended** |
| t3.2xlarge | 8 | 32 GB | Heavy workloads |
| m5.xlarge | 4 | 16 GB | Balanced compute |
| m5.2xlarge | 8 | 32 GB | High compute |
| c5.xlarge | 4 | 8 GB | Compute optimized |
| r5.xlarge | 4 | 32 GB | Memory optimized |

---

### Auto Scaling Group Configuration

#### `asg_min_size`
- **Description**: Minimum number of instances
- **Type**: Number
- **Default**: `1`
- **Valid Range**: 0 or greater
- **Recommendation**: Set to 1 for high availability

#### `asg_max_size`
- **Description**: Maximum number of instances
- **Type**: Number
- **Default**: `3`
- **Valid Range**: 1 or greater
- **Recommendation**: Set based on expected maximum load

#### `asg_desired_capacity`
- **Description**: Desired number of instances
- **Type**: Number
- **Default**: `1`
- **Valid Range**: Between `asg_min_size` and `asg_max_size`
- **Recommendation**: Start with 1, scale as needed

**Example Configurations:**

```hcl
# Development (cost-optimized)
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# Production (high availability)
asg_min_size         = 2
asg_max_size         = 10
asg_desired_capacity = 2

# Testing (minimal cost)
asg_min_size         = 0
asg_max_size         = 1
asg_desired_capacity = 0
```

---

### ECS Task Configuration

#### `task_cpu`
- **Description**: CPU units for ECS task (256 = 0.25 vCPU)
- **Type**: String
- **Default**: `"256"`
- **Valid Values**: `"256"`, `"512"`, `"1024"`, `"2048"`, `"4096"`

#### `task_memory`
- **Description**: Memory in MB for ECS task
- **Type**: String
- **Default**: `"512"`
- **Valid Combinations** (CPU / Memory):

| CPU | Valid Memory (MB) |
|-----|-------------------|
| 256 | 512, 1024, 2048 |
| 512 | 1024, 2048, 3072, 4096 |
| 1024 | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2048 | 4096-16384 (1024 increments) |
| 4096 | 8192-30720 (1024 increments) |

**Example Configurations:**

```hcl
# Small task (default)
task_cpu    = "256"
task_memory = "512"

# Medium task
task_cpu    = "512"
task_memory = "1024"

# Large task
task_cpu    = "1024"
task_memory = "2048"
```

#### `ecs_service_desired_count`
- **Description**: Number of ECS tasks to run
- **Type**: Number
- **Default**: `1`
- **Valid Range**: 0 or greater
- **Recommendation**: Start with 1, increase for redundancy

---

### CloudWatch Logs Configuration

#### `log_retention_days`
- **Description**: Number of days to retain CloudWatch logs
- **Type**: Number
- **Default**: `7`
- **Valid Values**: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
- **Recommendations**:
  - Development: 7 days
  - Staging: 30 days
  - Production: 90-365 days

---

### Tags Configuration

#### `additional_tags`
- **Description**: Additional tags to apply to all resources
- **Type**: Map of strings
- **Default**: `{}`
- **Example**:
```hcl
additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Compliance  = "HIPAA"
  Backup      = "Daily"
}
```

---

## Example Configurations

### Development Environment

```hcl
# terraform.tfvars
aws_region   = "us-west-2"
project_name = "myapp-dev"
environment  = "dev"

vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2

instance_type        = "t3.medium"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

task_cpu                  = "256"
task_memory               = "512"
ecs_service_desired_count = 1

log_retention_days = 7
```

### Production Environment

```hcl
# terraform.tfvars
aws_region   = "us-east-1"
project_name = "myapp-prod"
environment  = "production"

vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 3
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

instance_type        = "m5.xlarge"
asg_min_size         = 2
asg_max_size         = 10
asg_desired_capacity = 3

task_cpu                  = "512"
task_memory               = "1024"
ecs_service_desired_count = 3

log_retention_days = 90

additional_tags = {
  Owner      = "Platform Team"
  CostCenter = "Production"
  Backup     = "Daily"
}
```

### Cost-Optimized Testing

```hcl
# terraform.tfvars
aws_region   = "us-west-2"
project_name = "test"
environment  = "test"

vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 1
public_subnet_cidrs      = ["10.0.1.0/24"]

instance_type        = "t3.small"
asg_min_size         = 0
asg_max_size         = 1
asg_desired_capacity = 1

task_cpu                  = "256"
task_memory               = "512"
ecs_service_desired_count = 1

log_retention_days = 1
```

---

## Validation

All variables include validation rules to prevent invalid configurations:

- VPC CIDR must be valid IPv4 CIDR
- Availability zones count: 1-3
- ASG sizes must be logical (min ≤ desired ≤ max)
- Task CPU must be valid ECS value
- Log retention must be valid CloudWatch value
- Instance type must match EC2 naming pattern

---

## Cost Estimation

Approximate monthly costs (us-west-2):

| Configuration | Instance | Monthly Cost* |
|--------------|----------|---------------|
| Minimal (t3.small x1) | $15 | ~$20 |
| Default (t3.xlarge x1) | $120 | ~$130 |
| Production (m5.xlarge x3) | $345 | ~$370 |

*Includes EC2, EBS, data transfer, CloudWatch. S3 costs vary by usage.

Use AWS Pricing Calculator for accurate estimates: https://calculator.aws/

---

## Troubleshooting

### Variable Validation Errors

If you see validation errors:

```bash
# Check variable values
terraform console
> var.vpc_cidr
> var.asg_min_size
```

### Subnet CIDR Issues

Ensure subnet CIDRs:
- Are within VPC CIDR range
- Don't overlap
- Are large enough for your needs

```bash
# Test CIDR calculations
terraform console
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
```

---

## Additional Resources

- [AWS VPC CIDR Planning](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)
- [ECS Task Sizing](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [Terraform Variables](https://www.terraform.io/language/values/variables)
