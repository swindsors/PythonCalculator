# Quick Deployment Commands

## Choose Your Deployment Method

### Option 1: Automated CloudFormation Deployment (Fastest)
Use this if you want to deploy quickly and don't need to learn each service individually.

### Option 2: AWS Console Deployment (Visual & Educational)
Use this if you want to learn AWS services through the web interface with visual guidance.

### Option 3: Manual CLI Deployment (Advanced Learning)
Use this if you want to learn how each AWS service works by setting them up via command line.

---

## Option 1: CloudFormation Deployment

### Prerequisites Setup

### 1. Create EC2 Key Pair
```bash
aws ec2 create-key-pair \
  --key-name streamlit-calculator-key \
  --query 'KeyMaterial' \
  --output text > streamlit-calculator-key.pem

chmod 400 streamlit-calculator-key.pem
```

## Deployment Commands

### 1. Push Code to GitHub
```bash
git add .
git commit -m "Add deployment configuration files"
git push origin main
```

### 2. Deploy CloudFormation Stack
```bash
aws cloudformation create-stack \
  --stack-name streamlit-calculator-stack \
  --template-body file://cloudformation-template.yml \
  --parameters ParameterKey=EC2KeyPair,ParameterValue=streamlit-calculator-key \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 3. Monitor Stack Creation
```bash
aws cloudformation describe-stacks \
  --stack-name streamlit-calculator-stack \
  --query 'Stacks[0].StackStatus' \
  --region us-east-1
```

### 4. Wait for Stack Completion
```bash
aws cloudformation wait stack-create-complete \
  --stack-name streamlit-calculator-stack \
  --region us-east-1
```

### 5. Authorize GitHub Connection
**Important**: After stack creation, you need to authorize the GitHub connection:
1. Go to AWS Console → CodeStar → Connections
2. Find your connection (status will be "Pending")
3. Click "Update pending connection"
4. Complete GitHub authorization
5. Status should change to "Available"

### 6. Get Stack Outputs (EC2 IP, etc.)
```bash
aws cloudformation describe-stacks \
  --stack-name streamlit-calculator-stack \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

### 7. Manually Trigger Pipeline (if needed)
```bash
aws codepipeline start-pipeline-execution \
  --name streamlit-calculator-pipeline \
  --region us-east-1
```

## Monitoring Commands

### Check Pipeline Status
```bash
aws codepipeline get-pipeline-state \
  --name streamlit-calculator-pipeline \
  --region us-east-1
```

### SSH into EC2 Instance
```bash
ssh -i streamlit-calculator-key.pem ec2-user@[EC2_PUBLIC_IP]
```

### Check Application Logs
```bash
tail -f /home/ec2-user/streamlit.log
```

## Cleanup Commands (if needed)

### Delete CloudFormation Stack
```bash
aws cloudformation delete-stack \
  --stack-name streamlit-calculator-stack \
  --region us-east-1
```


### Delete EC2 Key Pair
```bash
aws ec2 delete-key-pair \
  --key-name streamlit-calculator-key \
  --region us-east-1
```

## Expected Timeline
- Stack creation: 5-10 minutes
- First pipeline execution: 3-5 minutes
- Total deployment time: 10-15 minutes

## Access Your Application
Once deployed, access at: `http://[EC2_PUBLIC_IP]:8501`

---

## Option 2: Manual Deployment (Educational)

### Phase 1: GitHub Setup
```bash
# 1. Create GitHub Personal Access Token (via web interface)
# 2. Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name github-token \
  --description "GitHub personal access token for CodePipeline" \
  --secret-string '{"token":"YOUR_GITHUB_TOKEN_HERE"}' \
  --region us-east-1
```

### Phase 2: Create S3 Bucket
```bash
aws s3 mb s3://streamlit-calculator-artifacts-804711833877 --region us-east-1
aws s3api put-bucket-versioning \
  --bucket streamlit-calculator-artifacts-804711833877 \
  --versioning-configuration Status=Enabled
```

### Phase 3: Create Security Group
```bash
aws ec2 create-security-group \
  --group-name streamlit-calculator-sg \
  --description "Security group for Streamlit Calculator" \
  --region us-east-1

# Note the Security Group ID from output, then:
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region us-east-1

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 8501 \
  --cidr 0.0.0.0/0 \
  --region us-east-1
```

### Phase 4: Create EC2 Key Pair
```bash
aws ec2 create-key-pair \
  --key-name streamlit-calculator-key \
  --query 'KeyMaterial' \
  --output text > streamlit-calculator-key.pem

chmod 400 streamlit-calculator-key.pem
```

### Phase 5: Create Instance Profile
```bash
aws iam create-instance-profile \
  --instance-profile-name streamlit-calculator-ec2-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name streamlit-calculator-ec2-profile \
  --role-name streamlit-calculator-ec2-role
```

### Phase 6: Launch EC2 Instance
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

### Phase 7: Create CodeDeploy Application
```bash
aws deploy create-application \
  --application-name streamlit-calculator \
  --compute-platform Server \
  --region us-east-1

aws deploy create-deployment-group \
  --application-name streamlit-calculator \
  --deployment-group-name streamlit-calculator-deployment-group \
  --service-role-arn arn:aws:iam::804711833877:role/streamlit-calculator-codedeploy-role \
  --deployment-config-name CodeDeployDefault.AllAtOneEC2 \
  --ec2-tag-filters Key=Name,Value=streamlit-calculator-instance,Type=KEY_AND_VALUE \
  --region us-east-1
```

### Phase 8: Get EC2 IP and Test
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=streamlit-calculator-instance" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region us-east-1
```

**Note**: For the manual approach, you'll need to create IAM roles, CodeBuild project, and CodePipeline through the AWS Console as detailed in the MANUAL_DEPLOYMENT_GUIDE.md file.

---

---

## Option 3: AWS Console Deployment (Visual Learning)

### Complete Visual Guide
Follow the **AWS_CONSOLE_DEPLOYMENT_GUIDE.md** for a complete step-by-step visual guide using the AWS web interface.

### Key Steps Summary:
1. **GitHub Setup**: Create CodeStar Connection (no tokens needed!)
2. **IAM Roles**: Create 4 service roles through IAM console
3. **S3 Bucket**: Create artifact storage bucket
4. **EC2 Setup**: Security Group → Key Pair → Launch Instance
5. **CodeBuild**: Create build project
6. **CodeDeploy**: Create application and deployment group
7. **CodePipeline**: Connect everything together
8. **Test**: Watch your app deploy automatically!

---

## Which Method Should You Choose?

- **CloudFormation (Option 1)**: Choose this if you want to deploy quickly and focus on the application
- **AWS Console (Option 2)**: Choose this if you want to learn AWS services visually through the web interface
- **Manual CLI (Option 3)**: Choose this if you want to learn AWS DevOps services in depth via command line

All methods result in the same final deployment - a fully automated CI/CD pipeline!

## Recommended Learning Path:
1. **Beginners**: Start with AWS Console (Option 2) for visual learning
2. **Intermediate**: Try Manual CLI (Option 3) for deeper understanding  
3. **Advanced**: Use CloudFormation (Option 1) for production deployments
