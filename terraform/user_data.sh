#!/bin/bash
set -e  # Exit on error

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script at $(date)"

# Update system
echo "Updating system packages..."
yum update -y

# Install mount-s3
echo "Installing mount-s3..."
curl -L https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm -o /tmp/mount-s3.rpm
yum install -y /tmp/mount-s3.rpm

# Verify mount-s3 installation
if ! command -v mount-s3 &> /dev/null; then
    echo "ERROR: mount-s3 installation failed"
    exit 1
fi
echo "mount-s3 installed successfully: $(mount-s3 --version)"

# Create mount point directory
echo "Creating mount point directory..."
mkdir -p /mnt/s3-bucket

# Configure ECS agent
echo "Configuring ECS agent..."
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_LOGGING=true" >> /etc/ecs/ecs.config
echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config

# Mount S3 bucket using mount-s3
echo "Mounting S3 bucket ${bucket_name}..."
mount-s3 ${bucket_name} /mnt/s3-bucket --allow-other --region ${aws_region}

# Verify mount
if mountpoint -q /mnt/s3-bucket; then
    echo "S3 bucket mounted successfully"
else
    echo "ERROR: S3 bucket mount failed"
    exit 1
fi

# Add to fstab for persistence
echo "s3://${bucket_name} /mnt/s3-bucket mount-s3 _netdev,nosuid,nodev,rw,allow-other,nofail 0 0" >> /etc/fstab

# Restart ECS agent to pick up new configuration
# echo "Restarting ECS agent..."
# systemctl restart ecs

# Wait for ECS agent to start
sleep 1

# Log mount status
echo "=== Mount Status ===" >> /var/log/s3-mount.log
echo "Timestamp: $(date)" >> /var/log/s3-mount.log
echo "S3 bucket ${bucket_name} mounted to /mnt/s3-bucket" >> /var/log/s3-mount.log
echo "Mount point check:" >> /var/log/s3-mount.log
mountpoint /mnt/s3-bucket >> /var/log/s3-mount.log 2>&1
echo "Directory contents:" >> /var/log/s3-mount.log
ls -la /mnt/s3-bucket >> /var/log/s3-mount.log 2>&1

echo "User data script completed successfully at $(date)"