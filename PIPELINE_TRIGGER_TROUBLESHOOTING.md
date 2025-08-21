# Pipeline Not Triggering on Git Push - Troubleshooting Guide

## Problem
Your CodePipeline is not automatically starting when you push code to GitHub.

## Common Causes & Solutions

### 1. CodeStar Connection Not Properly Authorized

**Check Connection Status:**
1. **Go to AWS Console** → Search **"CodeStar"** → Click **"CodeStar"**
2. **Click "Connections"** in left sidebar
3. **Find your connection** (should be named something like `streamlit-calculator-github-connection`)
4. **Check status** - it should show **"Available"**

**If Status is "Pending":**
1. **Click on the connection name**
2. **Click "Update pending connection"**
3. **Complete GitHub authorization** when prompted
4. **Status should change to "Available"**

### 2. GitHub Repository Permissions

**Check Repository Access:**
1. **Go to GitHub.com** → Your repository → **Settings** tab
2. **Click "Integrations"** in left sidebar
3. **Look for "AWS Connector for GitHub"**
4. **Should show access to your repository**

**If Missing or Limited Access:**
1. **Click "Configure"** next to AWS Connector
2. **Grant access** to your repository
3. **Save changes**

### 3. Pipeline Source Configuration

**Verify Pipeline Settings:**
1. **Go to CodePipeline** → Your pipeline → **Edit**
2. **Click "Edit" on Source stage**
3. **Verify these settings:**
   - **Source provider**: GitHub (Version 2)
   - **Connection**: Your CodeStar connection (should be "Available")
   - **Repository name**: `swindsors/PythonCalculator`
   - **Branch name**: `main`
   - **Change detection**: ✅ "Start the pipeline on source code change"

### 4. Branch Name Mismatch

**Common Issue**: Pipeline watching wrong branch

**Check Your Git Branch:**
```bash
git branch
# Should show: * main
```

**If you're on a different branch:**
```bash
git checkout main
git push origin main
```

**Update Pipeline if Needed:**
1. **CodePipeline** → Edit → Source stage
2. **Change "Branch name"** to match your actual branch
3. **Save changes**

### 5. GitHub Webhook Issues

**Check Webhooks (GitHub Side):**
1. **GitHub repository** → **Settings** → **Webhooks**
2. **Look for AWS webhook** (URL contains `amazonaws.com`)
3. **Should show green checkmark** (recent successful delivery)

**If Webhook is Missing or Failing:**
1. **Go to CodePipeline** → Edit → Source stage
2. **Temporarily change** to "No change detection"
3. **Save**, then **edit again**
4. **Change back** to "Start the pipeline on source code change"
5. **Save** - this recreates the webhook

### 6. Repository URL Format

**Verify Repository Name Format:**
- **Correct**: `swindsors/PythonCalculator`
- **Incorrect**: `https://github.com/swindsors/PythonCalculator.git`
- **Incorrect**: `github.com/swindsors/PythonCalculator`

## Step-by-Step Diagnostic

### Step 1: Test Manual Trigger
```bash
aws codepipeline start-pipeline-execution \
  --name streamlit-calculator-pipeline \
  --region us-east-1
```

**If this works**: Pipeline is healthy, issue is with automatic triggering
**If this fails**: Pipeline has configuration issues

### Step 2: Check Recent Pipeline History
1. **CodePipeline** → Your pipeline
2. **Look at "Execution history"**
3. **Check timestamps** - should show recent activity after pushes

### Step 3: Verify Git Push Actually Worked
```bash
# Check if your changes are on GitHub
git log --oneline -5
# Copy the latest commit hash

# Check on GitHub web interface
# Go to your repository and verify the commit is there
```

### Step 4: Check CloudTrail (Advanced)
1. **CloudTrail** → **Event history**
2. **Filter by**: Event name = `StartPipelineExecution`
3. **Look for automatic triggers** vs manual ones

## Quick Fixes to Try

### Fix 1: Recreate the Webhook
1. **CodePipeline** → Edit → Source stage
2. **Change detection**: Uncheck "Start the pipeline on source code change"
3. **Save**
4. **Edit again** → Check "Start the pipeline on source code change"
5. **Save**

### Fix 2: Update Connection
1. **CodeStar** → **Connections** → Your connection
2. **Click "Update connection"**
3. **Re-authorize with GitHub**

### Fix 3: Test with Different Branch
```bash
# Create test branch
git checkout -b test-trigger
echo "# Test trigger" >> README.md
git add README.md
git commit -m "Test pipeline trigger"
git push origin test-trigger

# Update pipeline to watch test-trigger branch temporarily
# Push another change and see if it triggers
```

## Manual Workaround

While troubleshooting, you can manually trigger the pipeline:

### Via AWS Console:
1. **CodePipeline** → Your pipeline
2. **Click "Release change"**

### Via AWS CLI:
```bash
aws codepipeline start-pipeline-execution \
  --name streamlit-calculator-pipeline \
  --region us-east-1
```

## Common Error Messages

### "Connection is not available"
- **Solution**: Re-authorize CodeStar Connection

### "Repository not found"
- **Solution**: Check repository name format and permissions

### "Branch not found"
- **Solution**: Verify branch name matches what's in pipeline

### "Webhook delivery failed"
- **Solution**: Recreate webhook by toggling change detection

## Verification Steps

After applying fixes:

1. **Make a small change** to any file
2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Test pipeline trigger"
   git push origin main
   ```
3. **Check CodePipeline** within 1-2 minutes
4. **Should see new execution** starting automatically

## Prevention

To avoid this issue in the future:
1. **Always use CodeStar Connections** (not GitHub v1)
2. **Verify connection status** after setup
3. **Test with small changes** before major deployments
4. **Monitor webhook health** in GitHub settings

## Still Not Working?

If none of these solutions work:

1. **Delete and recreate** the CodeStar Connection
2. **Delete and recreate** the pipeline Source stage
3. **Check AWS service health** status page
4. **Contact AWS support** if using paid support plan

The most common fix is re-authorizing the CodeStar Connection - try that first!
