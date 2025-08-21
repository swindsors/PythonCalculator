# CodeDeploy Deployment Troubleshooting Guide

## Issue: Application Files Not Deployed to EC2

If you're seeing only the CodeDeploy agent installer on your EC2 instance but no application files, the deployment is failing. Here's how to troubleshoot:

## Step 1: Check CodeDeploy Agent Status

Connect to your EC2 instance and run these commands:

```bash
# Check if CodeDeploy agent is running
sudo service codedeploy-agent status

# If not running, start it
sudo service codedeploy-agent start

# Check agent logs
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

## Step 2: Verify EC2 Instance Tags

Your EC2 instance must have the correct tags for CodeDeploy to target it:

1. **Go to EC2 Console** → **Instances**
2. **Select your instance** → **Tags tab**
3. **Verify you have**: 
   - **Key**: `Name`
   - **Value**: `streamlit-calculator-instance`

**If the tag is missing:**
1. **Click "Manage tags"**
2. **Add tag**: Key=`Name`, Value=`streamlit-calculator-instance`
3. **Save changes**

## Step 3: Check CodeDeploy Deployment Logs

1. **Go to CodeDeploy Console** → **Applications** → **streamlit-calculator**
2. **Click on "Deployments"**
3. **Click on the failed deployment**
4. **Check the deployment status and error messages**

Common errors and solutions:

### Error: "No instances were found"
- **Cause**: EC2 instance doesn't have the correct tags
- **Fix**: Add the `Name=streamlit-calculator-instance` tag to your EC2 instance

### Error: "The CodeDeploy agent did not find an AppSpec file"
- **Cause**: appspec.yml not in the root of your repository
- **Fix**: Ensure appspec.yml is in the root directory of your GitHub repo

### Error: "AccessDenied" or IAM permission errors
- **Cause**: Missing IAM permissions
- **Fix**: Check IAM roles (see Step 4)

## Step 4: Verify IAM Permissions

### Check EC2 Instance Role
1. **Go to EC2** → **Instances** → **Select your instance**
2. **Security tab** → **IAM role** should be `streamlit-calculator-ec2-role`
3. **If missing**: Actions → Security → Modify IAM role → Select the role

### Check CodeDeploy Service Role
1. **Go to CodeDeploy** → **Applications** → **streamlit-calculator**
2. **Deployment groups** → **streamlit-calculator-deployment-group**
3. **Service role** should be `arn:aws:iam::804711833877:role/streamlit-calculator-codedeploy-role`

## Step 5: Manual Deployment Test

Try creating a manual deployment to isolate the issue:

1. **Go to CodeDeploy** → **Applications** → **streamlit-calculator**
2. **Click "Create deployment"**
3. **Deployment group**: `streamlit-calculator-deployment-group`
4. **Revision type**: `My application is stored in GitHub`
5. **GitHub token name**: Use your GitHub connection
6. **Repository name**: `swindsors/PythonCalculator`
7. **Commit ID**: Use latest commit hash
8. **Click "Create deployment"**

## Step 6: Check Build Artifacts

The issue might be in the build stage not producing proper artifacts:

1. **Go to CodePipeline** → **streamlit-calculator-pipeline**
2. **Click on the Build stage** → **View details**
3. **Check build logs** for any errors
4. **Verify artifacts are created** in S3 bucket

## Step 7: Debug on EC2 Instance

Connect to your EC2 instance and check:

```bash
# Check if CodeDeploy agent is receiving deployments
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log

# Check if deployment directory exists
ls -la /opt/codedeploy-agent/deployment-root/

# Check for any deployment attempts
sudo find /opt/codedeploy-agent/deployment-root/ -name "*" -type f

# Check system logs
sudo tail -f /var/log/messages
```

## Step 8: Common Fixes

### Fix 1: Restart CodeDeploy Agent
```bash
sudo service codedeploy-agent stop
sudo service codedeploy-agent start
sudo service codedeploy-agent status
```

### Fix 2: Reinstall CodeDeploy Agent
```bash
sudo yum remove codedeploy-agent -y
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
```

### Fix 3: Check Network Connectivity
```bash
# Test connectivity to CodeDeploy service
curl -I https://codedeploy.us-east-1.amazonaws.com

# Check if instance can reach S3
aws s3 ls s3://streamlit-calculator-artifacts-804711833877/ --region us-east-1
```

## Step 9: Pipeline Trigger Test

Test if the pipeline triggers correctly:

1. **Make a small change** to your calculator.py file
2. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Test deployment trigger"
   git push origin main
   ```
3. **Watch the pipeline** in CodePipeline console
4. **Monitor each stage** for failures

## Step 10: Expected File Structure After Successful Deployment

After a successful deployment, you should see:

```bash
/home/ec2-user/streamlit-calculator/
├── calculator.py
├── requirements.txt
├── appspec.yml
├── buildspec.yml
├── scripts/
│   ├── install_dependencies.sh
│   ├── start_server.sh
│   └── stop_server.sh
└── [other project files]
```

## Quick Diagnostic Commands

Run these commands on your EC2 instance to get a quick status:

```bash
# Check CodeDeploy agent
sudo service codedeploy-agent status

# Check if Streamlit is running
ps aux | grep streamlit

# Check application directory
ls -la /home/ec2-user/streamlit-calculator/

# Check recent deployments
sudo ls -la /opt/codedeploy-agent/deployment-root/

# Check logs
sudo tail -20 /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

## Next Steps

1. **Start with Step 2** (verify EC2 tags) - this is the most common issue
2. **Check Step 3** (CodeDeploy deployment logs) for specific error messages
3. **Try Step 5** (manual deployment) to isolate pipeline vs. CodeDeploy issues
4. **Use Step 10** diagnostic commands to get current status

If you're still having issues after these steps, please share:
- The specific error messages from CodeDeploy console
- Output from the diagnostic commands
- CodeDeploy agent logs from the EC2 instance
