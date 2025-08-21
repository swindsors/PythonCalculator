# CodeBuild Stage Explained - What Happens During the Build

## Overview
The Build stage is where AWS CodeBuild takes your source code from GitHub and prepares it for deployment. Think of it as a virtual computer that downloads your code, installs dependencies, runs tests, and packages everything for the next stage.

## Step-by-Step Build Process

### 1. Environment Setup (30-60 seconds)
**What happens:**
- CodeBuild spins up a fresh Linux container (Amazon Linux 2)
- Installs Python 3.9 runtime
- Sets up a clean, isolated environment

**Why this matters:**
- Ensures consistent builds every time
- No leftover files from previous builds
- Same environment as production

### 2. Source Code Download (10-20 seconds)
**What happens:**
- Downloads your code from GitHub (the artifact from Source stage)
- Extracts all files to `/codebuild/output/src123456789/src/`
- Makes your `buildspec.yml` file available

**Files downloaded:**
```
/codebuild/output/src123456789/src/
├── calculator.py
├── requirements.txt
├── buildspec.yml
├── appspec.yml
├── scripts/
│   ├── install_dependencies.sh
│   ├── start_server.sh
│   └── stop_server.sh
└── [all other files]
```

### 3. Install Phase (30-90 seconds)
**What happens (from your buildspec.yml):**
```yaml
install:
  runtime-versions:
    python: 3.9
  commands:
    - echo Install phase started on `date`
    - pip install --upgrade pip
    - pip install -r requirements.txt
```

**Detailed breakdown:**
1. **Sets Python 3.9** as the active runtime
2. **Upgrades pip** to latest version
3. **Installs Streamlit** (from requirements.txt)
   - Downloads streamlit>=1.28.0
   - Installs all dependencies (pandas, numpy, etc.)
   - Creates virtual environment

**Console output you'll see:**
```
Install phase started on Wed Aug 21 17:30:15 UTC 2025
Requirement already satisfied: pip in /usr/local/lib/python3.9/site-packages (21.3.1)
Collecting pip
  Downloading pip-23.2.1-py3-none-any.whl (2.1 MB)
Successfully installed pip-23.2.1
Collecting streamlit>=1.28.0
  Downloading streamlit-1.28.0-py2.py3-none-any.whl (8.4 MB)
[... more dependency installations ...]
Successfully installed streamlit-1.28.0 [and dependencies]
```

### 4. Pre-Build Phase (5-10 seconds)
**What happens:**
```yaml
pre_build:
  commands:
    - echo Pre-build phase started on `date`
    - echo Testing the application
```

**Purpose:**
- This is where you'd run tests (unit tests, linting, etc.)
- Currently just logs messages
- Could be expanded to run: `python -m pytest tests/`

### 5. Build Phase (5-10 seconds)
**What happens:**
```yaml
build:
  commands:
    - echo Build phase started on `date`
    - echo Build completed on `date`
```

**Purpose:**
- For compiled languages, this would compile code
- For Python, usually just validation
- Could run code quality checks
- Could generate documentation

### 6. Post-Build Phase (5-10 seconds)
**What happens:**
```yaml
post_build:
  commands:
    - echo Post-build phase started on `date`
    - echo Build completed successfully
```

**Purpose:**
- Final cleanup
- Generate build reports
- Upload additional artifacts
- Send notifications

### 7. Artifact Creation (10-30 seconds)
**What happens:**
```yaml
artifacts:
  files:
    - '**/*'
  name: streamlit-calculator-$(date +%Y-%m-%d)
```

**Detailed process:**
1. **Packages all files** (`**/*` means everything)
2. **Creates a ZIP file** named like `streamlit-calculator-2025-08-21.zip`
3. **Uploads to S3** artifacts bucket
4. **Makes available** for Deploy stage

**Files included in artifact:**
- calculator.py (your Streamlit app)
- requirements.txt (dependencies)
- appspec.yml (deployment instructions)
- scripts/ folder (deployment scripts)
- All other project files

## What You See in AWS Console

### Build Logs
When you click on a build in CodeBuild, you'll see logs like:
```
[Container] 2025/08/21 17:30:10 Running command echo Install phase started on `date`
Install phase started on Wed Aug 21 17:30:10 UTC 2025

[Container] 2025/08/21 17:30:10 Running command pip install --upgrade pip
Requirement already satisfied: pip in /usr/local/lib/python3.9/site-packages

[Container] 2025/08/21 17:30:15 Running command pip install -r requirements.txt
Collecting streamlit>=1.28.0
  Downloading streamlit-1.28.0-py2.py3-none-any.whl (8.4 MB)
Successfully installed streamlit-1.28.0

[Container] 2025/08/21 17:30:45 Phase complete: INSTALL State: SUCCEEDED
[Container] 2025/08/21 17:30:45 Phase complete: PRE_BUILD State: SUCCEEDED
[Container] 2025/08/21 17:30:46 Phase complete: BUILD State: SUCCEEDED
[Container] 2025/08/21 17:30:47 Phase complete: POST_BUILD State: SUCCEEDED
[Container] 2025/08/21 17:30:50 Uploading S3 cache...
[Container] 2025/08/21 17:30:52 Completed 0 files with ... bytes transferred
```

### Build Metrics
- **Duration**: Usually 2-4 minutes total
- **Compute**: BUILD_GENERAL1_SMALL (3 GB RAM, 2 vCPUs)
- **Cost**: ~$0.005 per minute (very cheap!)

## Common Build Issues & Solutions

### 1. Requirements.txt Not Found
**Error:** `Could not open requirements file: [Errno 2] No such file or directory: 'requirements.txt'`
**Fix:** Make sure requirements.txt is in your repository root

### 2. Python Version Mismatch
**Error:** `Runtime version python:3.9 is not supported`
**Fix:** Update buildspec.yml to use supported version (3.8, 3.9, 3.10)

### 3. Dependency Installation Fails
**Error:** `ERROR: Could not find a version that satisfies the requirement`
**Fix:** Check package names in requirements.txt

### 4. Build Timeout
**Error:** `Build timed out`
**Fix:** Increase timeout in CodeBuild project settings

## Customizing Your Build

### Add Testing
```yaml
pre_build:
  commands:
    - echo Pre-build phase started on `date`
    - echo Running tests...
    - python -m pytest tests/ -v
    - echo Running linting...
    - flake8 calculator.py
```

### Add Code Quality Checks
```yaml
build:
  commands:
    - echo Build phase started on `date`
    - echo Checking code quality...
    - python -m pylint calculator.py
    - echo Build completed on `date`
```

### Environment Variables
You can add environment variables in CodeBuild:
```yaml
env:
  variables:
    ENVIRONMENT: "production"
    DEBUG: "false"
```

## Build Artifacts Flow

```
GitHub → CodeBuild → S3 Artifacts Bucket → CodeDeploy → EC2
```

1. **GitHub**: Source code
2. **CodeBuild**: Processes and packages code
3. **S3**: Stores the packaged artifact (ZIP file)
4. **CodeDeploy**: Downloads artifact from S3
5. **EC2**: Receives and runs the application

## Performance Tips

### Speed Up Builds
1. **Use caching** for dependencies
2. **Minimize artifact size** (exclude unnecessary files)
3. **Use smaller build environment** if possible
4. **Parallel testing** for multiple test files

### Example with Caching
```yaml
cache:
  paths:
    - '/root/.cache/pip/**/*'
```

## Monitoring Your Builds

### CloudWatch Logs
- All build output goes to CloudWatch
- Searchable and filterable
- Retained for debugging

### Build History
- CodeBuild keeps history of all builds
- Can compare successful vs failed builds
- Useful for troubleshooting

The build stage is essentially preparing your code for deployment - installing dependencies, running tests, and packaging everything so it can be deployed to your EC2 instance in the next stage!
