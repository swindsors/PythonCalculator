#!/bin/bash
yum update -y
yum install -y ruby wget python3 python3-pip
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
service codedeploy-agent start
chkconfig codedeploy-agent on
