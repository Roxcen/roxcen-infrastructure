# 🔐 GitHub Secrets Configuration Guide

## 📋 **Required Secrets Setup**

### **Step 1: Create Personal Access Token**

1. **Go to GitHub Settings:**
   - Navigate to: https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"

2. **Configure Token:**
   - **Name:** `Roxcen Infrastructure Access`
   - **Expiration:** `No expiration` (or 1 year)
   - **Scopes:** Check these boxes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
     - ✅ `admin:repo_hook` (Admin repo hooks)

3. **Save Token:**
   - Click "Generate token"
   - **IMPORTANT:** Copy the token immediately (you won't see it again)
   - Save it securely - you'll need it for both repositories

---

## 🏗️ **Infrastructure Repository Secrets**

### **Repository:** `Roxcen/roxcen-infrastructure`

**Navigate to:** https://github.com/Roxcen/roxcen-infrastructure/settings/secrets/actions

**Add these secrets:**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID | AWS credentials for Terraform |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key | AWS credentials for Terraform |
| `INFRASTRUCTURE_TOKEN` | Personal Access Token (from above) | Token to trigger other repositories |

---

## 🚀 **WebAPI Repository Secrets**

### **Repository:** `Roxcen/webapi` (or whatever your webapi repo is named)

**Navigate to:** https://github.com/Roxcen/webapi/settings/secrets/actions

**Add these secrets:**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID | AWS credentials for deployment |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key | AWS credentials for deployment |
| `INFRASTRUCTURE_TOKEN` | Personal Access Token (from above) | Token to access infrastructure repo |
| `DEV_DATABASE_URL` | `postgresql://user:pass@host:5432/db` | Development database connection |
| `DEV_REDIS_URL` | `redis://host:6379` | Development Redis connection |
| `PROD_DATABASE_URL` | `postgresql://user:pass@host:5432/db` | Production database connection |
| `PROD_REDIS_URL` | `redis://host:6379` | Production Redis connection |
| `JWT_SECRET_KEY` | Random secure string | JWT token encryption |

---

## 🔧 **How to Add Secrets via GitHub CLI**

### **For Infrastructure Repository:**
```bash
# Set AWS credentials
gh secret set AWS_ACCESS_KEY_ID --repo Roxcen/roxcen-infrastructure
gh secret set AWS_SECRET_ACCESS_KEY --repo Roxcen/roxcen-infrastructure

# Set infrastructure token
gh secret set INFRASTRUCTURE_TOKEN --repo Roxcen/roxcen-infrastructure
```

### **For WebAPI Repository:**
```bash
# Set AWS credentials  
gh secret set AWS_ACCESS_KEY_ID --repo Roxcen/webapi
gh secret set AWS_SECRET_ACCESS_KEY --repo Roxcen/webapi

# Set infrastructure token
gh secret set INFRASTRUCTURE_TOKEN --repo Roxcen/webapi

# Set database URLs (you'll be prompted to enter values)
gh secret set DEV_DATABASE_URL --repo Roxcen/webapi
gh secret set DEV_REDIS_URL --repo Roxcen/webapi
gh secret set PROD_DATABASE_URL --repo Roxcen/webapi
gh secret set PROD_REDIS_URL --repo Roxcen/webapi
gh secret set JWT_SECRET_KEY --repo Roxcen/webapi
```

---

## 🗄️ **AWS Credentials Setup**

### **Option 1: Use Existing AWS Credentials**
```bash
# Check your existing AWS credentials
aws configure list
cat ~/.aws/credentials

# Use the access key and secret from your AWS configuration
```

### **Option 2: Create New IAM User for CI/CD**
1. **Go to AWS IAM Console:**
   - Navigate to: https://console.aws.amazon.com/iam/
   - Click "Users" → "Create User"

2. **Configure User:**
   - **Username:** `roxcen-cicd`
   - **Access type:** Programmatic access only
   - **Permissions:** Attach policies:
     - `AmazonECS_FullAccess`
     - `AmazonEC2ContainerRegistryFullAccess`
     - `AmazonVPCFullAccess`
     - `AmazonS3FullAccess`
     - `CloudWatchFullAccess`
     - `IAMFullAccess`

3. **Save Credentials:**
   - Download CSV or copy Access Key ID and Secret Access Key
   - Use these for GitHub secrets

---

## ✅ **Verification Commands**

### **Check Infrastructure Repository Secrets:**
```bash
gh secret list --repo Roxcen/roxcen-infrastructure
```

### **Check WebAPI Repository Secrets:**
```bash
gh secret list --repo Roxcen/webapi
```

---

## 🚨 **Security Best Practices**

1. **✅ Never commit secrets to code**
2. **✅ Use environment-specific secrets**
3. **✅ Rotate access keys regularly**
4. **✅ Use least privilege IAM policies**
5. **✅ Monitor secret usage in audit logs**

---

**🎯 Next Step:** After configuring secrets, we'll create the S3 bucket for Terraform state!
