# ECS S3 Mount 自动部署指南

## 概述
这个 Terraform 配置将创建一个完整的 ECS 环境，使用 Auto Scaling Group 管理 EC2 实例，并通过 bind mount 方式将 S3 bucket 挂载到容器中。

## 架构组件
- **S3 Bucket**: 存储测试数据
- **VPC**: 包含公有子网和安全组
- **ECS Cluster**: 运行容器任务
- **Auto Scaling Group**: 管理 EC2 实例
- **IAM Roles**: 提供必要的权限
- **CloudWatch**: 日志监控

## 部署步骤

### 1. 准备环境
```bash
# 确保已安装 AWS CLI 和 Terraform
aws --version
terraform --version

# 配置 AWS 凭证
aws configure
```

### 2. 初始化 Terraform
```bash
cd terraform
terraform init
```

### 3. 配置变量（可选）
```bash
# 复制示例配置文件
cp terraform.tfvars.example terraform.tfvars

# 编辑配置文件（如需要）
# vim terraform.tfvars
```

### 4. 部署基础设施
```bash
# 查看执行计划
terraform plan

# 应用配置
terraform apply
```

### 5. 验证部署
部署完成后，Terraform 会输出重要信息，包括：
- S3 bucket 名称
- ECS cluster 名称
- 测试命令

## 测试验证

### 检查 ECS 集群状态
```bash
aws ecs describe-clusters --clusters $(terraform output -raw ecs_cluster_name)
```

### 检查服务运行状态
```bash
aws ecs describe-services --cluster $(terraform output -raw ecs_cluster_name) --services $(terraform output -raw ecs_service_name)
```

### 查看任务日志
```bash
# 获取任务 ID
TASK_ARN=$(aws ecs list-tasks --cluster $(terraform output -raw ecs_cluster_name) --query 'taskArns[0]' --output text)

# 查看日志
aws logs get-log-events --log-group-name $(terraform output -raw cloudwatch_log_group) --log-stream-name "ecs/s3-test-app/$(basename $TASK_ARN)"
```

### 检查 Auto Scaling Group
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw autoscaling_group_name)
```

## 功能测试

### S3 数据读取测试
容器启动后会自动执行以下测试：
1. 列出 S3 挂载目录内容
2. 读取测试文件 `sample.txt`
3. 读取配置文件 `config.json`
4. 验证数据完整性

### 扩缩容测试
```bash
# 扩容到 2 个实例
aws autoscaling set-desired-capacity --auto-scaling-group-name $(terraform output -raw autoscaling_group_name) --desired-capacity 2

# 缩容到 1 个实例
aws autoscaling set-desired-capacity --auto-scaling-group-name $(terraform output -raw autoscaling_group_name) --desired-capacity 1
```

## 清理资源
```bash
# 删除所有创建的资源
terraform destroy
```

## 故障排除

### 常见问题
1. **权限问题**: 确保 AWS 凭证有足够权限
2. **区域问题**: 确认 AWS 区域设置正确
3. **实例启动失败**: 检查 CloudWatch 日志

### 调试命令
```bash
# 检查实例状态
aws ec2 describe-instances --filters "Name=tag:Project,Values=ecs-s3-mount"

# 检查 ECS 容器实例
aws ecs list-container-instances --cluster $(terraform output -raw ecs_cluster_name)

# 查看系统日志
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2"
```

## 配置说明

### 关键配置项
- **实例类型**: t3.micro (适合测试)
- **最小实例数**: 1
- **最大实例数**: 3
- **容器资源**: 256 CPU, 512MB 内存
- **日志保留**: 7 天

### 安全配置
- 所有 IAM 角色遵循最小权限原则
- S3 访问仅限于指定 bucket
- 网络访问通过安全组控制

这个配置提供了一个完整、简化的 ECS S3 挂载解决方案，适合快速测试和验证。