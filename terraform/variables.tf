# ============================================
# AWS Configuration Variables
# ============================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "ecs-s3-mount"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod, test)"
  type        = string
  default     = "test"
}

# ============================================
# S3 Configuration Variables
# ============================================

variable "bucket_name" {
  description = "S3 bucket name for testing (will have random suffix added)"
  type        = string
  default     = "ecs-s3-test-bucket"
}

# ============================================
# VPC Configuration Variables
# ============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones_count" {
  description = "Number of availability zones to use for subnets"
  type        = number
  default     = 2
  
  validation {
    condition     = var.availability_zones_count >= 1 && var.availability_zones_count <= 3
    error_message = "Availability zones count must be between 1 and 3."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "At least one public subnet CIDR must be provided."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Automatically assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = true
}

# ============================================
# EC2 Instance Configuration Variables
# ============================================

variable "instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3.xlarge"
  
  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

# ============================================
# Auto Scaling Group Configuration Variables
# ============================================

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.asg_min_size >= 0
    error_message = "ASG minimum size must be greater than or equal to 0."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
  
  validation {
    condition     = var.asg_max_size >= 1
    error_message = "ASG maximum size must be greater than or equal to 1."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.asg_desired_capacity >= 0
    error_message = "ASG desired capacity must be greater than or equal to 0."
  }
}

# ============================================
# ECS Task Configuration Variables
# ============================================

variable "task_cpu" {
  description = "CPU units for the ECS task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
  
  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (in MB) for the ECS task"
  type        = string
  default     = "512"
  
  validation {
    condition     = can(regex("^[0-9]+$", var.task_memory))
    error_message = "Task memory must be a valid number."
  }
}

variable "ecs_service_desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1
  
  validation {
    condition     = var.ecs_service_desired_count >= 0
    error_message = "ECS service desired count must be greater than or equal to 0."
  }
}

# ============================================
# CloudWatch Logs Configuration Variables
# ============================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch retention periods."
  }
}

# ============================================
# Tags Configuration Variables
# ============================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
