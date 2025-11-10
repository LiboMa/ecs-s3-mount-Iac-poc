# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.test_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.test_bucket.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.s3_mount_service.name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ecs_sg.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "test_commands" {
  description = "Commands to test the deployment"
  value = {
    check_cluster = "aws ecs describe-clusters --clusters ${aws_ecs_cluster.main.name} --region ${var.aws_region}"
    check_service = "aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.s3_mount_service.name} --region ${var.aws_region}"
    check_tasks   = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --region ${var.aws_region}"
    view_logs     = "aws logs describe-log-streams --log-group-name ${aws_cloudwatch_log_group.ecs_logs.name} --region ${var.aws_region}"
    check_asg     = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${aws_autoscaling_group.ecs_asg.name} --region ${var.aws_region}"
  }
}