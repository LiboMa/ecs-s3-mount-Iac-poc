#!/bin/bash

# ECS S3 Mount 一键部署脚本
set -e

echo "=========================================="
echo "ECS S3 Mount 自动部署开始"
echo "=========================================="

# 检查必要工具
echo "检查必要工具..."
if ! command -v terraform &> /dev/null; then
    echo "错误: 未找到 terraform，请先安装"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "错误: 未找到 aws cli，请先安装"
    exit 1
fi

# 检查 AWS 凭证
echo "检查 AWS 凭证..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "错误: AWS 凭证未配置，请运行 'aws configure'"
    exit 1
fi

# 进入 terraform 目录
cd terraform

# 初始化 Terraform
echo "初始化 Terraform..."
terraform init

# 验证配置
echo "验证 Terraform 配置..."
terraform validate

# 显示执行计划
echo "生成执行计划..."
terraform plan

# 询问是否继续
read -p "是否继续部署？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "部署已取消"
    exit 0
fi

# 执行部署
echo "开始部署..."
terraform apply -auto-approve

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="

# 显示重要信息
echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
echo "ECS Cluster: $(terraform output -raw ecs_cluster_name)"
echo "CloudWatch 日志组: $(terraform output -raw cloudwatch_log_group)"

echo ""
echo "验证命令："
echo "aws ecs describe-services --cluster $(terraform output -raw ecs_cluster_name) --services $(terraform output -raw ecs_service_name)"

echo ""
echo "查看日志："
echo "aws logs describe-log-streams --log-group-name $(terraform output -raw cloudwatch_log_group)"

echo ""
echo "清理资源："
echo "terraform destroy"