# AWS Console Deployment Guide for Streamlit Calculator

This guide will teach you how to deploy your Streamlit calculator to AWS using the AWS Console (web interface). You'll learn each service by clicking through the AWS web interface step by step.

## Why Use the AWS Console?

- **Visual Learning**: See exactly what each service looks like
- **Beginner Friendly**: No command line knowledge required
- **Interactive**: Click through each step at your own pace
- **Educational**: Perfect for understanding AWS services visually

## Prerequisites

1. **AWS Account**: Account ID 804711833877
2. **GitHub Repository**: https://github.com/swindsors/PythonCalculator.git (make sure all files are pushed)
3. **GitHub Personal Access Token**: We'll create this together

---

## Phase 1: Set Up GitHub Integration with CodeStar Connections

### Step 1.1: Create CodeStar Connection to GitHub

**What this does**: Creates a secure, managed connection between AWS and your GitHub account. This is the modern, recommended approach that doesn't require storing tokens.

1. **Open AWS Console** → Search for **"CodeStar"** → Click **"CodeStar"**
2. **Click "Connections"** in the left sidebar
3. **Click "Create connection"**
4. **Select provider**: **GitHub**
5. **Connection name**: `github-connection`
6. **Click "Connect to GitHub"**
7. **GitHub will open** → **Click "Authorize AWS Connector for GitHub"**
8. **Select your GitHub account** if prompted
9. **Click "Connect"**
10. **You should see "Connection status: Available"**
11. **Copy the Connection ARN** (looks like: `arn:aws:codestar-connections:us-east-1:804711833877:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

**Important**: Keep this Connection ARN handy - you'll need it for CodePipeline setup.

---

## Phase 2: Create IAM Roles

**What IAM does**: Controls permissions - who can do what in AWS. Each service needs specific permissions.

### Step 2.1: Create EC2 Instance Role

**What this does**: Allows EC2 to download deployment files from S3.

1. **AWS Console** → Search **"IAM"** → Click it
2. **Click "Roles"** (left sidebar) → **"Create role"**
3. **Select "AWS service"** → **"EC2"** → **"Next"**
4. **Search and select these policies**:
   - ✅ `CloudWatchAgentServerPolicy`
5. **Click "Next"**
6. **Role name**: `streamlit-calculator-ec2-role`
7. **Click "Create role"**

**Now add a custom policy**:
8. **Click on your new role** → **"Add permissions"** → **"Create inline policy"**
9. **Click "JSON" tab** and paste:
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
10. **Click "Next"** → **Policy name**: `S3AccessPolicy` → **"Create policy"**

### Step 2.2: Create CodeBuild Service Role

1. **IAM** → **"Roles"** → **"Create role"**
2. **Select "AWS service"** → **"CodeBuild"** → **"Next"**
3. **Click "Create policy"** (opens new tab)
4. **Click "JSON" tab** and paste:
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
5. **Click "Next"** → **Policy name**: `StreamlitCalculatorCodeBuildPolicy` → **"Create policy"**
6. **Go back to the role creation tab** → **Refresh** → **Search and select your new policy**
7. **Click "Next"** → **Role name**: `streamlit-calculator-codebuild-role` → **"Create role"**

### Step 2.3: Create CodeDeploy Service Role

1. **IAM** → **"Roles"** → **"Create role"**
2. **Select "AWS service"** → **"CodeDeploy"** → **"Next"**
3. **Search and select**: `AWSCodeDeployRole`
4. **Click "Next"** → **Role name**: `streamlit-calculator-codedeploy-role` → **"Create role"**

### Step 2.4: Create CodePipeline Service Role

1. **IAM** → **"Roles"** → **"Create role"**
2. **Select "AWS service"** → **"CodePipeline"** → **"Next"**
3. **Click "Create policy"** (opens new tab)
4. **Click "JSON" tab** and paste:
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
5. **Click "Next"** → **Policy name**: `StreamlitCalculatorCodePipelinePolicy` → **"Create policy"**
6. **Go back to role tab** → **Refresh** → **Select your new policy**
7. **Click "Next"** → **Role name**: `streamlit-calculator-codepipeline-role` → **"Create role"**

---

## Phase 3: Create S3 Bucket for Artifacts

**What this does**: Creates storage for build files that move between pipeline stages.

1. **AWS Console** → Search **"S3"** → Click it
2. **Click "Create bucket"**
3. **Bucket name**: `streamlit-calculator-artifacts-804711833877`
4. **Region**: `US East (N. Virginia) us-east-1`
5. **Scroll down** → **Bucket Versioning**: **Enable**
6. **Keep all other defaults** → **Click "Create bucket"**

---

## Phase 4: Create EC2 Infrastructure

### Step 4.1: Create Security Group

**What this does**: Acts as a firewall controlling network traffic to your server.

1. **AWS Console** → Search **"EC2"** → Click it
2. **Click "Security Groups"** (left sidebar) → **"Create security group"**
3. **Security group name**: `streamlit-calculator-sg`
4. **Description**: `Security group for Streamlit Calculator`
5. **VPC**: Leave default
6. **Inbound rules** → **Add rule**:
   - **Type**: `SSH`
   - **Source**: `Anywhere-IPv4` (0.0.0.0/0)
   - **Description**: `SSH access`
7. **Add rule** again:
   - **Type**: `Custom TCP`
   - **Port range**: `8501`
   - **Source**: `Anywhere-IPv4` (0.0.0.0/0)
   - **Description**: `Streamlit application`
8. **Click "Create security group"**

### Step 4.2: Create Key Pair

**What this does**: Creates SSH keys for secure access to your server.

1. **EC2 Console** → **"Key Pairs"** (left sidebar) → **"Create key pair"**
2. **Name**: `streamlit-calculator-key`
3. **Key pair type**: `RSA`
4. **Private key file format**: `.pem`
5. **Click "Create key pair"**
6. **The .pem file will download automatically** - save it securely!

### Step 4.3: Launch EC2 Instance

**What this does**: Creates the actual server that will host your application.

1. **EC2 Console** → **"Instances"** → **"Launch instances"**
2. **Name**: `streamlit-calculator-instance`
3. **Application and OS Images**:
   - **Amazon Machine Image**: `Amazon Linux 2023 AMI` (should be selected by default)
4. **Instance type**: `t2.micro` (Free tier eligible)
5. **Key pair**: Select `streamlit-calculator-key`
6. **Network settings** → **Edit**:
   - **Select existing security group**: `streamlit-calculator-sg`
7. **Advanced details** → **IAM instance profile**: `streamlit-calculator-ec2-profile`
   
   **Wait! We need to create the instance profile first:**
   
   **Create Instance Profile**:
   - **Open new tab** → **IAM** → **Roles** → **streamlit-calculator-ec2-role**
   - **Copy the Role ARN** (looks like: arn:aws:iam::804711833877:role/streamlit-calculator-ec2-role)
   - **Go back to EC2 tab** → **Advanced details** → **User data** → **Text** → Paste:
   
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

# Create instance profile and attach role
aws iam create-instance-profile --instance-profile-name streamlit-calculator-ec2-profile
aws iam add-role-to-instance-profile --instance-profile-name streamlit-calculator-ec2-profile --role-name streamlit-calculator-ec2-role
```

8. **Click "Launch instance"**
9. **Wait for instance to be "Running"** (about 2-3 minutes)

**Fix the Instance Profile** (since we couldn't set it during launch):
1. **Select your instance** → **Actions** → **Security** → **Modify IAM role**
2. **IAM role**: `streamlit-calculator-ec2-role`
3. **Click "Update IAM role"**

---

## Phase 5: Set Up CodeBuild

**What this does**: Creates a build environment that compiles and tests your application.

1. **AWS Console** → Search **"CodeBuild"** → Click it
2. **Click "Create build project"**
3. **Project configuration**:
   - **Project name**: `streamlit-calculator-build`
   - **Description**: `Build project for Streamlit Calculator`
4. **Source**:
   - **Source provider**: `GitHub`
   - **Repository**: `Repository in my GitHub account`
   - **GitHub repository**: `https://github.com/swindsors/PythonCalculator.git`
   - **Source version**: `refs/heads/main`
   - **Git clone depth**: `1`
5. **Environment**:
   - **Environment image**: `Managed image`
   - **Operating system**: `Amazon Linux 2`
   - **Runtime(s)**: `Standard`
   - **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:3.0`
   - **Environment type**: `Linux`
   - **Service role**: `Existing service role`
   - **Role ARN**: Select `streamlit-calculator-codebuild-role`
6. **Buildspec**:
   - **Build specifications**: `Use a buildspec file`
   - (This will use the buildspec.yml file in your repository)
7. **Artifacts**:
   - **Type**: `No artifacts`
8. **Click "Create build project"**

---

## Phase 6: Set Up CodeDeploy

**What this does**: Manages the deployment of your application to EC2.

### Step 6.1: Create CodeDeploy Application

1. **AWS Console** → Search **"CodeDeploy"** → Click it
2. **Click "Create application"**
3. **Application name**: `streamlit-calculator`
4. **Compute platform**: `EC2/On-premises`
5. **Click "Create application"**

### Step 6.2: Create Deployment Group

1. **Click your new application** → **"Create deployment group"**
2. **Deployment group name**: `streamlit-calculator-deployment-group`
3. **Service role**: Select `streamlit-calculator-codedeploy-role`
4. **Deployment type**: `In-place`
5. **Environment configuration**: `Amazon EC2 instances`
6. **Tag group 1**:
   - **Key**: `Name`
   - **Value**: `streamlit-calculator-instance`
7. **Deployment configuration**: `CodeDeployDefault.AllAtOneEC2`
8. **Load balancer**: Uncheck "Enable load balancing"
9. **Click "Create deployment group"**

---

## Phase 7: Set Up CodePipeline

**What this does**: Orchestrates the entire CI/CD process.

1. **AWS Console** → Search **"CodePipeline"** → Click it
2. **Click "Create pipeline"**
3. **Pipeline settings**:
   - **Pipeline name**: `streamlit-calculator-pipeline`
   - **Service role**: `Existing service role`
   - **Role ARN**: Select `streamlit-calculator-codepipeline-role`
   - **Artifact store**: `Default location`
   - **Bucket**: Select `streamlit-calculator-artifacts-804711833877`
4. **Click "Next"**

### Source Stage:
5. **Source provider**: `GitHub (Version 2)`
6. **Connection**: Select your `github-connection` (the one you created in Phase 1)
7. **Repository name**: `swindsors/PythonCalculator`
8. **Branch name**: `main`
9. **Change detection options**: `Start the pipeline on source code change` (should be checked by default)
10. **Output artifact format**: `CodePipeline default`
11. **Click "Next"**

### Build Stage:
11. **Build provider**: `AWS CodeBuild`
12. **Region**: `US East (N. Virginia)`
13. **Project name**: Select `streamlit-calculator-build`
14. **Click "Next"**

### Deploy Stage:
15. **Deploy provider**: `AWS CodeDeploy`
16. **Region**: `US East (N. Virginia)`
17. **Application name**: Select `streamlit-calculator`
18. **Deployment group**: Select `streamlit-calculator-deployment-group`
19. **Click "Next"**

### Review:
20. **Review all settings** → **Click "Create pipeline"**

---

## Phase 8: Test Your Deployment

### Step 8.1: Watch the Pipeline Execute

1. **Your pipeline should start automatically**
2. **Watch each stage**:
   - **Source**: ✅ Downloads code from GitHub
   - **Build**: ⏳ Runs CodeBuild (takes 2-3 minutes)
   - **Deploy**: ⏳ Deploys to EC2 (takes 2-3 minutes)

### Step 8.2: Get Your EC2 Public IP

1. **Go to EC2** → **Instances** → **Select your instance**
2. **Copy the "Public IPv4 address"**

### Step 8.3: Access Your Application

1. **Open your browser**
2. **Go to**: `http://[YOUR_EC2_PUBLIC_IP]:8501`
3. **You should see your Streamlit calculator!**

---

## Understanding What Just Happened

Here's the flow you just created:

1. **You push code to GitHub** 📤
2. **GitHub webhook triggers CodePipeline** 🔔
3. **CodePipeline downloads your code** ⬇️
4. **CodeBuild runs your buildspec.yml** 🔨
   - Installs Python dependencies
   - Packages everything for deployment
5. **CodeDeploy takes the built application** 🚀
6. **CodeDeploy runs your appspec.yml on EC2** ⚙️
   - Stops old version
   - Copies new files
   - Starts new version
7. **Your Streamlit app is live!** 🎉

---

## Making Changes

Now whenever you want to update your calculator:

1. **Make changes to your code locally**
2. **Push to GitHub**: `git push origin main`
3. **Watch the pipeline automatically deploy your changes!**

---

## Troubleshooting

### Pipeline Fails at Source Stage
- **Check**: CodeStar Connection status (should show "Available")
- **Fix**: Go to CodeStar → Connections → Select your connection → If status is "Pending", complete the authorization
- **Alternative**: Delete and recreate the CodeStar connection

### Build Fails
- **Check**: CodeBuild logs (click on the failed build)
- **Common issues**: 
  - Missing `requirements.txt`
  - Wrong `buildspec.yml` syntax

### Deploy Fails
- **Check**: CodeDeploy logs
- **Common issues**:
  - CodeDeploy agent not running on EC2
  - Wrong IAM permissions
  - `appspec.yml` syntax errors

### Can't Access Application
- **Check**: Security group allows port 8501
- **Check**: EC2 instance is running
- **SSH into EC2**: `ssh -i streamlit-calculator-key.pem ec2-user@[IP]`
- **Check logs**: `tail -f /home/ec2-user/streamlit.log`

---

## Cost Breakdown

- **EC2 t2.micro**: ~$8.50/month (FREE with AWS Free Tier)
- **S3 storage**: ~$0.10/month
- **CodeBuild**: $0.005 per build minute
- **CodePipeline**: $1/month
- **CodeDeploy**: FREE for EC2
- **Total**: ~$10/month (or ~$1/month with Free Tier)

---

## What You've Learned

Congratulations! You now understand:

✅ **GitHub Integration**: How to securely connect GitHub to AWS
✅ **IAM Roles**: How AWS services get permissions to work together
✅ **S3 Storage**: How build artifacts flow through your pipeline
✅ **EC2 Setup**: How to configure servers for hosting applications
✅ **Security Groups**: How to control network access
✅ **CodeBuild**: How to automatically build and test code
✅ **CodeDeploy**: How to automatically deploy applications
✅ **CodePipeline**: How to orchestrate the entire CI/CD process

You've built a production-ready, automated deployment pipeline using the AWS Console! This knowledge applies to any application you want to deploy on AWS.

---

## Next Steps

1. **Try making changes** to your calculator and push them to GitHub
2. **Watch the automatic deployment** happen
3. **Explore the AWS Console** to see logs and metrics
4. **Add more features** to your calculator
5. **Consider adding**:
   - SSL certificate for HTTPS
   - Custom domain name
   - Load balancer for high availability
   - Auto Scaling for multiple instances

You're now ready to deploy any Python application to AWS! 🚀
