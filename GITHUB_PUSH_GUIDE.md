# 🚀 Push Infrastructure Repository to GitHub - Step-by-Step Guide

## 📋 **Prerequisites Check:**
- ✅ Infrastructure repository is ready and committed
- ✅ Git repository initialized locally
- ✅ All files committed (working tree clean)

## 🔧 **Method 1: Using GitHub CLI (Recommended)**

### **1. Install GitHub CLI (if not already installed):**
```bash
# macOS
brew install gh

# Or download from: https://cli.github.com/
```

### **2. Login to GitHub CLI:**
```bash
gh auth login
# Follow the prompts to authenticate
```

### **3. Create and Push Repository:**
```bash
cd /Users/sathishkumarkaruppannan/Documents/GitProject/roxcen-infrastructure

# Create GitHub repository
gh repo create Roxcen/roxcen-infrastructure \
  --public \
  --description "Infrastructure as Code for Roxcen platform - AWS ECS, VPC, and deployment automation" \
  --clone=false

# Add remote origin
git remote add origin https://github.com/Roxcen/roxcen-infrastructure.git

# Push to GitHub
git push -u origin main
```

---

## 🌐 **Method 2: Manual GitHub Creation**

### **1. Create Repository on GitHub:**
1. Go to https://github.com/Roxcen
2. Click "New repository"
3. Repository name: `roxcen-infrastructure`
4. Description: `Infrastructure as Code for Roxcen platform - AWS ECS, VPC, and deployment automation`
5. Set to **Public**
6. **DO NOT** initialize with README (we already have one)
7. Click "Create repository"

### **2. Connect Local Repository:**
```bash
cd /Users/sathishkumarkaruppannan/Documents/GitProject/roxcen-infrastructure

# Add remote origin
git remote add origin https://github.com/Roxcen/roxcen-infrastructure.git

# Push to GitHub
git push -u origin main
```

---

## ✅ **Verification Steps:**

After pushing, verify the repository is correctly set up:

### **1. Check Repository Structure on GitHub:**
- Navigate to https://github.com/Roxcen/roxcen-infrastructure
- Verify all directories are present:
  - `applications/webapi/`
  - `modules/ecs-api/` and `modules/vpc/`
  - `environments/webapi/dev/` and `environments/webapi/prod/`
  - `.github/workflows/infrastructure-deploy.yml`

### **2. Check Repository Settings:**
- Go to repository Settings
- Ensure "Actions" are enabled
- Set branch protection rules if needed

### **3. Verify Remote Connection:**
```bash
cd roxcen-infrastructure
git remote -v
# Should show:
# origin  https://github.com/Roxcen/roxcen-infrastructure.git (fetch)
# origin  https://github.com/Roxcen/roxcen-infrastructure.git (push)
```

---

## 🔐 **Next: Configure Repository Access**

After successful push, you'll need to:

1. **Set up GitHub Secrets** (covered in next step)
2. **Configure branch protection** (optional but recommended)
3. **Set up team access** (if working with a team)

---

**🎯 Run the commands above to push your infrastructure repository to GitHub!**
