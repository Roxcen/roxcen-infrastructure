# ⚠️ AWS Permissions Issue - Infrastructure Deployment

## 🔍 **Issue Identified:**
The current AWS user `roxcen-app-dev` doesn't have VPC creation permissions:
```
Error: User is not authorized to perform: ec2:CreateVpc
```

## 🎯 **Solutions:**

### **Option 1: Use Admin User for Infrastructure** (Recommended)
Create a separate IAM user with admin permissions for infrastructure deployment:
```bash
# Create infrastructure user with admin permissions
aws iam create-user --user-name roxcen-infrastructure-admin
aws iam attach-user-policy --user-name roxcen-infrastructure-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name roxcen-infrastructure-admin
```

### **Option 2: Add VPC Permissions to Current User**
Add VPC and networking permissions to `roxcen-app-dev`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:CreateSubnet", 
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:AllocateAddress",
        "ec2:Describe*",
        "ec2:AttachInternetGateway",
        "ec2:AssociateRouteTable",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Option 3: Use Existing VPC** (Quick Fix)
Configure WebAPI to use existing VPC resources instead of creating new ones.

## 🚀 **Recommended Approach:**
1. **Create infrastructure admin user** with full permissions
2. **Deploy shared infrastructure** with admin user  
3. **Deploy applications** with application user (roxcen-app-dev)

This follows security best practices by separating infrastructure and application permissions.

---

**⚡ Quick Fix:** I'll update the configuration to use existing VPC resources for now, then you can create the proper admin user later.
