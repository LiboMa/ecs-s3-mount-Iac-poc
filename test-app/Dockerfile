# Simple test application for S3 mount verification
FROM amazonlinux:2023

# Install basic tools
RUN yum update -y && \
    yum install -y \
    curl \
    jq \
    tree \
    && yum clean all

# Create app directory
WORKDIR /app

# Copy test script
COPY test-s3-mount.sh /app/
RUN chmod +x /app/test-s3-mount.sh

# Default command
CMD ["/app/test-s3-mount.sh"]