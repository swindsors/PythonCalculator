# Quick Deployment Commands

## Prerequisites Setup

### 1. Create GitHub Personal Access Token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` and `admin:repo_hook` scopes
3. Copy the token

### 2. Store GitHub Token in AWS Secrets Manager
```bash
aws secretsmanager create-secret \
  --name github-token \
  --description "GitHub personal access token for CodePipeline" \
  --secret-string '{"token":"YOUR_GITHUB_TOKEN_HERE"}' \
  --region us-east-1
```

### 3. Create EC2 Key Pair
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

### 5. Get Stack Outputs (EC2 IP, etc.)
```bash
aws cloudformation describe-stacks \
  --stack-name streamlit-calculator-stack \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

### 6. Manually Trigger Pipeline (if needed)
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

### Delete GitHub Token from Secrets Manager
```bash
aws secretsmanager delete-secret \
  --secret-id github-token \
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
