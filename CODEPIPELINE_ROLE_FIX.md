# Fix CodePipeline AssumeRole Error

## Problem
You're getting this error: "CodePipeline is not authorized to perform AssumeRole on role arn:aws:iam::804711833877:role/streamlit-calculator-codepipeline-role"

## Root Cause
The IAM role's trust policy doesn't allow the CodePipeline service to assume the role.

## Manual Fix Steps

### Step 1: Go to IAM Console
1. **Open AWS Console** → Search **"IAM"** → Click it
2. **Click "Roles"** in the left sidebar
3. **Find and click** `streamlit-calculator-codepipeline-role`

### Step 2: Check Trust Policy
1. **Click the "Trust relationships" tab**
2. **Click "Edit trust policy"**
3. **You should see something like this**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### Step 3: Fix the Trust Policy (if incorrect)
If the trust policy is missing or incorrect, **replace it with this**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### Step 4: Save Changes
1. **Click "Update policy"**
2. **Wait a few seconds** for the change to propagate

### Step 5: Add Missing Permissions (if needed)
The role also needs permission to use CodeStar Connections. Check if this policy exists:

1. **Click the "Permissions" tab**
2. **Look for a policy** that includes `codestar-connections:UseConnection`
3. **If missing**, click "Add permissions" → "Create inline policy"
4. **Use JSON editor** and add:

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
        },
        {
            "Effect": "Allow",
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*"
        }
    ]
}
```

5. **Name the policy**: `StreamlitCalculatorCodePipelinePolicy`
6. **Click "Create policy"**

### Step 6: Test the Fix
1. **Go to CodePipeline** → Find your pipeline
2. **Click "Release change"** to trigger it manually
3. **Watch the pipeline execute** - it should work now

## Alternative: Quick CLI Fix

If you prefer command line, you can also fix this with AWS CLI:

### Update Trust Policy
```bash
aws iam update-assume-role-policy \
  --role-name streamlit-calculator-codepipeline-role \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'
```

### Add CodeStar Connections Permission
```bash
aws iam put-role-policy \
  --role-name streamlit-calculator-codepipeline-role \
  --policy-name CodeStarConnectionsPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*"
        }
    ]
}'
```

## Why This Happened
This error typically occurs when:
1. **Role was created incorrectly** - Wrong trust policy
2. **Missing permissions** - Role can't use CodeStar Connections
3. **Timing issue** - Role was created but policies weren't attached properly

## Verification
After fixing, you should see:
- ✅ **Trust policy** allows `codepipeline.amazonaws.com`
- ✅ **Permissions** include S3, CodeBuild, CodeDeploy, and CodeStar Connections
- ✅ **Pipeline runs** without AssumeRole errors

The fix should take effect immediately, and your pipeline should work on the next execution!
