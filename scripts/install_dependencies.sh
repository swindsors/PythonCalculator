#!/bin/bash
set -e  # Exit on any error

echo "Starting dependency installation..."

# Update system packages
yum update -y

# Install Python 3 and pip if not already installed
yum install -y python3 python3-pip

# Ensure CodeDeploy agent is running (don't reinstall)
if ! service codedeploy-agent status > /dev/null 2>&1; then
    echo "Starting CodeDeploy agent..."
    service codedeploy-agent start
fi

# Create application directory if it doesn't exist
mkdir -p /home/ec2-user/streamlit-calculator
chown ec2-user:ec2-user /home/ec2-user/streamlit-calculator

echo "Dependency installation completed successfully"
