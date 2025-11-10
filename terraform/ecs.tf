# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "s3_mount_task" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "s3-test-app"
      image     = "amazonlinux:2023"
      essential = true
      
      mountPoints = [
        {
          sourceVolume  = "s3-volume"
          containerPath = "/app/s3-data"
          readOnly      = false
        }
      ]

      command = [
        "/bin/bash",
        "-c",
        "echo 'Starting S3 mount test...' && ls -la /app/s3-data && echo 'Contents of test-data directory:' && ls -la /app/s3-data/test-data/ && echo 'Reading sample.txt:' && cat /app/s3-data/test-data/sample.txt && echo 'Reading config.json:' && cat /app/s3-data/test-data/config.json && echo 'S3 mount test completed successfully!' && tail -f /dev/null"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "s3-volume"
    host_path = "/mnt/s3-bucket"
  }

  tags = local.common_tags
}

# ECS Service
resource "aws_ecs_service" "s3_mount_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.s3_mount_task.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs_sg.id]
  }

  depends_on = [aws_autoscaling_group.ecs_asg]

  tags = local.common_tags
}