#!/bin/bash

# ECS S3 Mount 验证脚本
set -e

echo "=========================================="
echo "ECS S3 Mount 部署验证"
echo "=========================================="

cd terraform

# 检查 Terraform 输出是否可用
if ! terraform output &> /dev/null; then
    echo "错误: 未找到 Terraform 状态，请先运行部署"
    exit 1
fi

# 获取输出变量
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
ASG_NAME=$(terraform output -raw autoscaling_group_name)

echo "集群名称: $CLUSTER_NAME"
echo "服务名称: $SERVICE_NAME"
echo "S3 Bucket: $BUCKET_NAME"
echo ""

# 1. 检查 ECS 集群状态
echo "1. 检查 ECS 集群状态..."
aws ecs describe-clusters --clusters $CLUSTER_NAME --query 'clusters[0].status' --output text

# 2. 检查服务状态
echo "2. 检查 ECS 服务状态..."
SERVICE_STATUS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].status' --output text)
echo "服务状态: $SERVICE_STATUS"

RUNNING_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].runningCount' --output text)
DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].desiredCount' --output text)
echo "运行任务数: $RUNNING_COUNT/$DESIRED_COUNT"

# 3. 检查任务状态
echo "3. 检查任务状态..."
TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query 'taskArns' --output text)
if [ -n "$TASK_ARNS" ]; then
    echo "找到任务: $(echo $TASK_ARNS | wc -w) 个"
    for TASK_ARN in $TASK_ARNS; do
        TASK_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].lastStatus' --output text)
        echo "任务状态: $TASK_STATUS"
    done
else
    echo "未找到运行中的任务"
fi

# 4. 检查 Auto Scaling Group
echo "4. 检查 Auto Scaling Group..."
INSTANCE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances | length(@)' --output text)
echo "ASG 实例数: $INSTANCE_COUNT"

# 5. 检查 S3 bucket
echo "5. 检查 S3 bucket..."
aws s3 ls s3://$BUCKET_NAME/test-data/

# 6. 查看最新日志
echo "6. 查看最新日志..."
LOG_STREAMS=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --order-by LastEventTime --descending --max-items 1 --query 'logStreams[0].logStreamName' --output text)

if [ "$LOG_STREAMS" != "None" ] && [ -n "$LOG_STREAMS" ]; then
    echo "最新日志流: $LOG_STREAMS"
    echo "最近的日志事件:"
    aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAMS --limit 10 --query 'events[*].message' --output text
else
    echo "未找到日志流"
fi

echo ""
echo "=========================================="
echo "验证完成"
echo "=========================================="

# 提供有用的命令
echo ""
echo "有用的命令:"
echo "查看所有日志流:"
echo "aws logs describe-log-streams --log-group-name $LOG_GROUP"
echo ""
echo "实时查看日志:"
echo "aws logs tail $LOG_GROUP --follow"
echo ""
echo "扩容测试:"
echo "aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 2"