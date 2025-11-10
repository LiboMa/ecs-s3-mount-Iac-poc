# Get latest ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" "ecs_template" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_ecs_cluster.main.name
    bucket_name  = aws_s3_bucket.test_bucket.id
    aws_region   = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-ecs-instance"
    })
  }

  tags = local.common_tags
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.project_name}-asg"
  vpc_zone_identifier       = aws_subnet.public[*].id
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [aws_ecs_cluster.main]
}