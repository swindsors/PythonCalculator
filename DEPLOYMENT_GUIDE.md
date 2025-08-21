# AWS Deployment Guide for Streamlit Calculator

This guide will walk you through deploying your Streamlit calculator to AWS EC2 using CodePipeline and CodeBuild from your GitHub repository.

## Overview

The deployment architecture includes:
- **GitHub Repository**: Source code repository
- **AWS CodePipeline**: Orchestrates the CI/CD process
- **AWS CodeBuild**: Builds and tests the application
- **AWS CodeDeploy**: Deploys the application to EC2
- **Amazon EC2**: Hosts the Streamlit application
- **Amazon S3**: Stores build artifacts

## Prerequisites

1. **AWS Account**: Account ID 804711833877
2. **GitHub Repository**: https://github.com/swindsors/PythonCalculator.git
3. **AWS CLI**: Installed and configured with appropriate permissions
4. **EC2 Key Pair**: For SSH access to the EC2 instance

## Step-by-Step Deployment Process

### Step 1: Prepare GitHub Repository

1. **Push all files to GitHub**:
   ```bash
   git add .
   git commit -m "Add deployment configuration files"
   git push origin main
   ```

2. **Verify repository structure**:
   ```
   PythonCalculator/
   ├── calculator.py
   ├── requirements.txt
   ├── buildspec.yml
   ├── appspec.yml
   ├── cloudformation-template.yml
   └── scripts/
       ├── install_dependencies.sh
       ├── start_server.sh
       └── stop_server.sh
   ```

### Step 2: Note About GitHub Connection

**Important**: The CloudFormation template now uses CodeStar Connections instead of personal access tokens. After the stack is created, you'll need to complete the GitHub authorization:

1. **After stack creation**, go to AWS Console → CodeStar → Connections
2. **Find your connection** (will show as "Pending")
3. **Click "Update pending connection"**
4. **Complete the GitHub authorization** when prompted
5. **Connection status should change to "Available"**

This is a one-time setup that provides more secure integration with GitHub.

### Step 3: Create EC2 Key Pair (if you don't have one)

```bash
aws ec2 create-key-pair \
  --key-name streamlit-calculator-key \
  --query 'KeyMaterial' \
  --output text > streamlit-calculator-key.pem

chmod 400 streamlit-calculator-key.pem
```

### Step 4: Deploy CloudFormation Stack

1. **Deploy the infrastructure**:
   ```bash
   aws cloudformation create-stack \
     --stack-name streamlit-calculator-stack \
     --template-body file://cloudformation-template.yml \
     --parameters ParameterKey=EC2KeyPair,ParameterValue=streamlit-calculator-key \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

2. **Monitor stack creation**:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name streamlit-calculator-stack \
     --query 'Stacks[0].StackStatus' \
     --region us-east-1
   ```

3. **Wait for completion** (typically 5-10 minutes):
   ```bash
   aws cloudformation wait stack-create-complete \
     --stack-name streamlit-calculator-stack \
     --region us-east-1
   ```

### Step 5: Get Stack Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name streamlit-calculator-stack \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

This will show you:
- EC2 Instance ID
- EC2 Public IP
- Streamlit Application URL
- CodePipeline Name

### Step 6: Trigger Initial Deployment

The CodePipeline will automatically trigger when you push changes to the main branch. To manually trigger:

```bash
aws codepipeline start-pipeline-execution \
  --name streamlit-calculator-pipeline \
  --region us-east-1
```

### Step 7: Monitor Deployment

1. **Check CodePipeline status**:
   ```bash
   aws codepipeline get-pipeline-state \
     --name streamlit-calculator-pipeline \
     --region us-east-1
   ```

2. **View CodeBuild logs**:
   - Go to AWS Console → CodeBuild → Build projects → streamlit-calculator-build
   - Click on the latest build to view logs

3. **View CodeDeploy status**:
   - Go to AWS Console → CodeDeploy → Applications → streamlit-calculator
   - Check deployment status

### Step 8: Access Your Application

Once deployment is complete, access your Streamlit calculator at:
```
http://[EC2_PUBLIC_IP]:8501
```

## File Explanations

### buildspec.yml
- **Purpose**: Defines the build process for CodeBuild
- **Phases**:
  - `install`: Sets up Python 3.9 and installs dependencies
  - `pre_build`: Runs tests (can be expanded)
  - `build`: Builds the application
  - `post_build`: Finalizes the build
- **Artifacts**: Packages all files for deployment

### appspec.yml
- **Purpose**: Defines deployment process for CodeDeploy
- **Files**: Specifies where to copy application files on EC2
- **Permissions**: Sets file ownership and permissions
- **Hooks**: Defines lifecycle events:
  - `BeforeInstall`: Installs system dependencies
  - `ApplicationStart`: Starts the Streamlit server
  - `ApplicationStop`: Stops the Streamlit server

### Deployment Scripts

#### scripts/install_dependencies.sh
- Updates the system
- Installs Python 3 and pip
- Installs and starts CodeDeploy agent
- Creates application directory

#### scripts/start_server.sh
- Installs Python dependencies
- Kills existing Streamlit processes
- Starts Streamlit server on port 8501
- Verifies server startup

#### scripts/stop_server.sh
- Gracefully stops Streamlit processes
- Force kills if necessary
- Verifies shutdown

### CloudFormation Template
Creates all necessary AWS resources:

#### IAM Roles and Policies
- **CodeBuildServiceRole**: Allows CodeBuild to access logs and S3
- **CodePipelineServiceRole**: Orchestrates the pipeline
- **CodeDeployServiceRole**: Manages deployments
- **EC2InstanceRole**: Allows EC2 to access S3 and CloudWatch

#### Infrastructure
- **S3 Bucket**: Stores build artifacts
- **EC2 Instance**: Hosts the application (t2.micro with Amazon Linux 2)
- **Security Group**: Opens ports 22 (SSH) and 8501 (Streamlit)

#### CI/CD Pipeline
- **CodeBuild Project**: Builds the application
- **CodeDeploy Application**: Manages deployments
- **CodePipeline**: Orchestrates the entire process

## Troubleshooting

### Common Issues

1. **Pipeline fails at Source stage**:
   - Verify GitHub token is correct in Secrets Manager
   - Check repository permissions

2. **Build fails**:
   - Check buildspec.yml syntax
   - Verify requirements.txt is correct
   - Review CodeBuild logs

3. **Deployment fails**:
   - Check EC2 instance has CodeDeploy agent running
   - Verify IAM roles have correct permissions
   - Check appspec.yml syntax

4. **Application not accessible**:
   - Verify security group allows port 8501
   - Check if Streamlit is running: `ps aux | grep streamlit`
   - Review application logs: `tail -f /home/ec2-user/streamlit.log`

### Useful Commands

**SSH into EC2 instance**:
```bash
ssh -i streamlit-calculator-key.pem ec2-user@[EC2_PUBLIC_IP]
```

**Check Streamlit logs**:
```bash
tail -f /home/ec2-user/streamlit.log
```

**Restart Streamlit manually**:
```bash
sudo su - ec2-user
cd /home/ec2-user/streamlit-calculator
pkill -f streamlit
nohup python3 -m streamlit run calculator.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &
```

## Cost Considerations

- **EC2 t2.micro**: ~$8.50/month (free tier eligible)
- **S3 storage**: Minimal cost for artifacts
- **CodeBuild**: $0.005 per build minute
- **CodePipeline**: $1 per active pipeline per month
- **CodeDeploy**: Free for EC2 deployments

## Security Best Practices

1. **Restrict SSH access**: Update security group to allow SSH only from your IP
2. **Use HTTPS**: Consider adding SSL/TLS certificate
3. **Regular updates**: Keep EC2 instance and dependencies updated
4. **Monitor logs**: Set up CloudWatch for monitoring
5. **Backup**: Regular snapshots of EC2 instance

## Next Steps

1. **Custom Domain**: Set up Route 53 for custom domain
2. **Load Balancer**: Add Application Load Balancer for high availability
3. **Auto Scaling**: Configure Auto Scaling Group for multiple instances
4. **Monitoring**: Set up CloudWatch dashboards and alarms
5. **Testing**: Add automated tests to the build process
