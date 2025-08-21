# Manual AWS Deployment Guide for Streamlit Calculator

This guide will teach you how to manually set up AWS CodePipeline, CodeBuild, and CodeDeploy to deploy your Streamlit calculator to EC2. You'll learn each service by configuring it step by step.

## Learning Objectives

By the end of this guide, you'll understand:
- How to create and configure EC2 instances for hosting applications
- How IAM roles and policies work in AWS
- How to set up CodeBuild for continuous integration
- How to configure CodeDeploy for application deployment
- How to create CodePipeline to orchestrate the entire CI/CD process
- How these services work together to create an automated deployment pipeline

## Prerequisites

1. **AWS Account**: Account ID 804711833877
2. **GitHub Repository**: https://github.com/swindsors/PythonCalculator.git
3. **AWS CLI**: Installed and configured
4. **GitHub Personal Access Token**: For CodePipeline integration

---

## Phase 1: Set Up GitHub Integration

### Step 1.1: Create GitHub Personal Access Token

**What this does**: Creates a secure token that AWS can use to access your GitHub repository.

1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name: `AWS-CodePipeline-Token`
4. Select scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Full control of repository hooks)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again)

### Step 1.2: Store Token in AWS Secrets Manager

**What this does**: Securely stores your GitHub token so CodePipeline can access it.

```bash
aws secretsmanager create-secret \
  --name github-token \
  --description "GitHub personal access token for CodePipeline" \
  --secret-string '{"token":"YOUR_GITHUB_TOKEN_HERE"}' \
  --region us-east-1
```

**Learning Point**: Secrets Manager is AWS's service for storing sensitive information like API keys, passwords, and tokens securely.

---

## Phase 2: Create IAM Roles and Policies

**What IAM does**: Identity and Access Management (IAM) controls who can do what in AWS. Each service needs specific permissions to function.

### Step 2.1: Create EC2 Instance Role

**What this does**: Allows EC2 instances to access other AWS services (like S3 for downloading deployment artifacts).

1. Go to AWS Console → IAM → Roles → Create role
2. Select "AWS service" → "EC2" → Next
3. Attach policies:
   - `CloudWatchAgentServerPolicy` (for logging)
   - Click "Create policy" for custom policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::streamlit-calculator-artifacts-804711833877",
                "arn:aws:s3:::streamlit-calculator-artifacts-804711833877/*"
            ]
        }
    ]
}
```

4. Name the policy: `StreamlitCalculatorEC2Policy`
5. Name the role: `streamlit-calculator-ec2-role`

### Step 2.2: Create CodeBuild Service Role

**What this does**: Allows CodeBuild to write logs and access S3 for artifacts.

1. IAM → Roles → Create role
2. Select "AWS service" → "CodeBuild" → Next
3. Create custom policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:us-east-1:804711833877:log-group:/aws/codebuild/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::streamlit-calculator-artifacts-804711833877/*"
        }
    ]
}
```

4. Name the policy: `StreamlitCalculatorCodeBuildPolicy`
5. Name the role: `streamlit-calculator-codebuild-role`

### Step 2.3: Create CodeDeploy Service Role

**What this does**: Allows CodeDeploy to manage deployments to EC2 instances.

1. IAM → Roles → Create role
2. Select "AWS service" → "CodeDeploy" → Next
3. Attach managed policy: `AWSCodeDeployRole`
4. Name the role: `streamlit-calculator-codedeploy-role`

### Step 2.4: Create CodePipeline Service Role

**What this does**: Allows CodePipeline to orchestrate the entire CI/CD process.

1. IAM → Roles → Create role
2. Select "AWS service" → "CodePipeline" → Next
3. Create custom policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject",
                "s3:GetBucketVersioning"
            ],
            "Resource": [
                "arn:aws:s3:::streamlit-calculator-artifacts-804711833877",
                "arn:aws:s3:::streamlit-calculator-artifacts-804711833877/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "arn:aws:codebuild:us-east-1:804711833877:project/streamlit-calculator-build"
        },
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*"
        }
    ]
}
```

4. Name the policy: `StreamlitCalculatorCodePipelinePolicy`
5. Name the role: `streamlit-calculator-codepipeline-role`

---

## Phase 3: Create S3 Bucket for Artifacts

**What this does**: Creates storage for build artifacts that move between pipeline stages.

### Step 3.1: Create S3 Bucket

```bash
aws s3 mb s3://streamlit-calculator-artifacts-804711833877 --region us-east-1
```

### Step 3.2: Enable Versioning

```bash
aws s3api put-bucket-versioning \
  --bucket streamlit-calculator-artifacts-804711833877 \
  --versioning-configuration Status=Enabled
```

**Learning Point**: Versioning allows CodePipeline to track different versions of your artifacts as they move through the pipeline.

---

## Phase 4: Create and Configure EC2 Instance

**What this does**: Creates the server that will host your Streamlit application.

### Step 4.1: Create Security Group

**What this does**: Acts as a virtual firewall controlling network traffic to your EC2 instance.

```bash
aws ec2 create-security-group \
  --group-name streamlit-calculator-sg \
  --description "Security group for Streamlit Calculator" \
  --region us-east-1
```

Get the Security Group ID from the output, then add rules:

```bash
# Allow SSH access (port 22)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region us-east-1

# Allow Streamlit access (port 8501)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 8501 \
  --cidr 0.0.0.0/0 \
  --region us-east-1
```

### Step 4.2: Create EC2 Key Pair

**What this does**: Creates SSH keys for secure access to your EC2 instance.

```bash
aws ec2 create-key-pair \
  --key-name streamlit-calculator-key \
  --query 'KeyMaterial' \
  --output text > streamlit-calculator-key.pem

chmod 400 streamlit-calculator-key.pem
```

### Step 4.3: Create Instance Profile

**What this does**: Attaches the IAM role to EC2 so it can access other AWS services.

```bash
aws iam create-instance-profile \
  --instance-profile-name streamlit-calculator-ec2-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name streamlit-calculator-ec2-profile \
  --role-name streamlit-calculator-ec2-role
```

### Step 4.4: Launch EC2 Instance

**What this does**: Creates the actual server with all necessary software pre-installed.

```bash
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --count 1 \
  --instance-type t2.micro \
  --key-name streamlit-calculator-key \
  --security-group-ids sg-xxxxxxxxx \
  --iam-instance-profile Name=streamlit-calculator-ec2-profile \
  --user-data file://user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=streamlit-calculator-instance},{Key=Environment,Value=production}]' \
  --region us-east-1
```

Create the `user-data.sh` file first:

```bash
#!/bin/bash
yum update -y
yum install -y ruby wget python3 python3-pip
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
service codedeploy-agent start
chkconfig codedeploy-agent on
```

**Learning Point**: User data scripts run when the instance first starts, allowing you to install software and configure the system automatically.

---

## Phase 5: Set Up CodeBuild

**What this does**: Creates a build environment that compiles and tests your application.

### Step 5.1: Create CodeBuild Project

1. Go to AWS Console → CodeBuild → Build projects → Create build project
2. **Project configuration**:
   - Project name: `streamlit-calculator-build`
   - Description: `Build project for Streamlit Calculator`

3. **Source**:
   - Source provider: GitHub
   - Repository: `https://github.com/swindsors/PythonCalculator.git`
   - Source version: `refs/heads/main`

4. **Environment**:
   - Environment image: Managed image
   - Operating system: Amazon Linux 2
   - Runtime: Standard
   - Image: `aws/codebuild/amazonlinux2-x86_64-standard:3.0`
   - Environment type: Linux
   - Service role: `streamlit-calculator-codebuild-role`

5. **Buildspec**:
   - Use a buildspec file (it will use the `buildspec.yml` in your repo)

6. **Artifacts**:
   - Type: No artifacts (CodePipeline will handle this)

7. Click "Create build project"

**Learning Point**: CodeBuild uses the `buildspec.yml` file in your repository to know how to build your application. This file defines the build phases and commands.

---

## Phase 6: Set Up CodeDeploy

**What this does**: Manages the deployment of your application to EC2 instances.

### Step 6.1: Create CodeDeploy Application

```bash
aws deploy create-application \
  --application-name streamlit-calculator \
  --compute-platform Server \
  --region us-east-1
```

### Step 6.2: Create Deployment Group

```bash
aws deploy create-deployment-group \
  --application-name streamlit-calculator \
  --deployment-group-name streamlit-calculator-deployment-group \
  --service-role-arn arn:aws:iam::804711833877:role/streamlit-calculator-codedeploy-role \
  --deployment-config-name CodeDeployDefault.AllAtOneEC2 \
  --ec2-tag-filters Key=Name,Value=streamlit-calculator-instance,Type=KEY_AND_VALUE \
  --region us-east-1
```

**Learning Point**: Deployment groups define which EC2 instances receive deployments. We're using EC2 tags to identify the target instances.

---

## Phase 7: Set Up CodePipeline

**What this does**: Orchestrates the entire CI/CD process, connecting GitHub → CodeBuild → CodeDeploy.

### Step 7.1: Create Pipeline

1. Go to AWS Console → CodePipeline → Pipelines → Create pipeline
2. **Pipeline settings**:
   - Pipeline name: `streamlit-calculator-pipeline`
   - Service role: `streamlit-calculator-codepipeline-role`
   - Artifact store: `streamlit-calculator-artifacts-804711833877`

3. **Source stage**:
   - Source provider: GitHub (Version 1)
   - Repository: `swindsors/PythonCalculator`
   - Branch: `main`
   - Change detection options: GitHub webhooks

4. **Build stage**:
   - Build provider: AWS CodeBuild
   - Project name: `streamlit-calculator-build`

5. **Deploy stage**:
   - Deploy provider: AWS CodeDeploy
   - Application name: `streamlit-calculator`
   - Deployment group: `streamlit-calculator-deployment-group`

6. Click "Create pipeline"

**Learning Point**: CodePipeline automatically creates webhooks in your GitHub repository so that pushes to the main branch trigger the pipeline.

---

## Phase 8: Test the Deployment

### Step 8.1: Push Code to GitHub

```bash
git add .
git commit -m "Add deployment configuration files"
git push origin main
```

### Step 8.2: Monitor the Pipeline

1. Go to CodePipeline → `streamlit-calculator-pipeline`
2. Watch each stage execute:
   - **Source**: Downloads code from GitHub
   - **Build**: Runs CodeBuild to compile/test
   - **Deploy**: Uses CodeDeploy to deploy to EC2

### Step 8.3: Get EC2 Public IP

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=streamlit-calculator-instance" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region us-east-1
```

### Step 8.4: Access Your Application

Open your browser to: `http://[EC2_PUBLIC_IP]:8501`

---

## Understanding the Deployment Flow

Here's what happens when you push code to GitHub:

1. **GitHub Webhook** → Triggers CodePipeline
2. **CodePipeline Source Stage** → Downloads code from GitHub to S3
3. **CodePipeline Build Stage** → Triggers CodeBuild
4. **CodeBuild** → Runs `buildspec.yml` commands, uploads artifacts to S3
5. **CodePipeline Deploy Stage** → Triggers CodeDeploy
6. **CodeDeploy** → Downloads artifacts from S3, runs `appspec.yml` deployment steps
7. **EC2 Instance** → Executes deployment scripts, starts Streamlit application

---

## Key Files Explained

### buildspec.yml
```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      python: 3.9
    commands:
      - pip install --upgrade pip
      - pip install -r requirements.txt
  build:
    commands:
      - echo "Build completed"
artifacts:
  files:
    - '**/*'
```

**What it does**: Tells CodeBuild how to build your application. The artifacts section specifies which files to pass to the next stage.

### appspec.yml
```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ec2-user/streamlit-calculator
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      runas: ec2-user
  ApplicationStop:
    - location: scripts/stop_server.sh
      runas: ec2-user
```

**What it does**: Tells CodeDeploy how to deploy your application. The hooks define scripts to run at different deployment phases.

---

## Troubleshooting Common Issues

### Pipeline Fails at Source Stage
- Check GitHub token in Secrets Manager
- Verify repository permissions
- Ensure webhook was created in GitHub

### Build Fails
- Check CodeBuild logs in AWS Console
- Verify `buildspec.yml` syntax
- Ensure `requirements.txt` is correct

### Deployment Fails
- SSH into EC2: `ssh -i streamlit-calculator-key.pem ec2-user@[IP]`
- Check CodeDeploy agent: `sudo service codedeploy-agent status`
- Check deployment logs: `sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log`

### Application Not Accessible
- Check security group allows port 8501
- Verify Streamlit is running: `ps aux | grep streamlit`
- Check application logs: `tail -f /home/ec2-user/streamlit.log`

---

## Cost Breakdown

- **EC2 t2.micro**: ~$8.50/month (free tier eligible)
- **S3 storage**: ~$0.10/month for artifacts
- **CodeBuild**: $0.005 per build minute
- **CodePipeline**: $1/month per active pipeline
- **CodeDeploy**: Free for EC2 deployments
- **Total**: ~$10/month (or ~$1/month with free tier)

---

## What You've Learned

By completing this manual setup, you now understand:

1. **IAM Roles and Policies**: How AWS services authenticate and authorize actions
2. **EC2 Configuration**: How to launch and configure virtual servers
3. **CodeBuild**: How to create automated build processes
4. **CodeDeploy**: How to automate application deployments
5. **CodePipeline**: How to orchestrate CI/CD workflows
6. **Service Integration**: How AWS services work together
7. **Security Groups**: How to control network access
8. **S3 Artifacts**: How build artifacts flow between services

This hands-on experience gives you deep knowledge of AWS DevOps services that you can apply to future projects!
