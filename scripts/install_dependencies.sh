#!/bin/bash
yum update -y
yum install -y python3 python3-pip

# Install CodeDeploy agent if not already installed
if ! rpm -qa | grep -q codedeploy-agent; then
    yum install -y ruby wget
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    service codedeploy-agent start
fi

# Create application directory if it doesn't exist
mkdir -p /home/ec2-user/streamlit-calculator
chown ec2-user:ec2-user /home/ec2-user/streamlit-calculator
