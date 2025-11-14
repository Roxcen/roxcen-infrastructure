# 🔐 **Complete AWS Permissions Required for Roxcen Infrastructure**

Based on our Terraform modules, here are ALL the AWS permissions needed:

## 📋 **Required AWS Services & Permissions**

### **1. VPC & Networking (✅ You added these)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:Describe*",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    }
  ]
}
```

### **2. ECS (Elastic Container Service) - REQUIRED**
```json
{
  "Effect": "Allow",
  "Action": [
    "ecs:CreateCluster",
    "ecs:DeleteCluster",
    "ecs:RegisterTaskDefinition",
    "ecs:DeregisterTaskDefinition",
    "ecs:CreateService",
    "ecs:UpdateService",
    "ecs:DeleteService",
    "ecs:Describe*",
    "ecs:List*",
    "ecs:TagResource",
    "ecs:UntagResource"
  ],
  "Resource": "*"
}
```

### **3. ECR (Container Registry) - REQUIRED**
```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:CreateRepository",
    "ecr:DeleteRepository",
    "ecr:PutLifecyclePolicy",
    "ecr:DeleteLifecyclePolicy",
    "ecr:Describe*",
    "ecr:List*",
    "ecr:TagResource",
    "ecr:UntagResource"
  ],
  "Resource": "*"
}
```

### **4. Application Load Balancer - REQUIRED**
```json
{
  "Effect": "Allow",
  "Action": [
    "elasticloadbalancing:CreateLoadBalancer",
    "elasticloadbalancing:DeleteLoadBalancer",
    "elasticloadbalancing:CreateTargetGroup",
    "elasticloadbalancing:DeleteTargetGroup",
    "elasticloadbalancing:CreateListener",
    "elasticloadbalancing:DeleteListener",
    "elasticloadbalancing:ModifyLoadBalancerAttributes",
    "elasticloadbalancing:ModifyTargetGroup",
    "elasticloadbalancing:ModifyTargetGroupAttributes",
    "elasticloadbalancing:Describe*",
    "elasticloadbalancing:AddTags",
    "elasticloadbalancing:RemoveTags"
  ],
  "Resource": "*"
}
```

### **5. IAM Roles & Policies - REQUIRED**
```json
{
  "Effect": "Allow",
  "Action": [
    "iam:CreateRole",
    "iam:DeleteRole",
    "iam:AttachRolePolicy",
    "iam:DetachRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:GetRole",
    "iam:GetRolePolicy",
    "iam:ListRolePolicies",
    "iam:ListAttachedRolePolicies",
    "iam:PassRole",
    "iam:TagRole",
    "iam:UntagRole"
  ],
  "Resource": "*"
}
```

### **6. CloudWatch Logs - REQUIRED**
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:DeleteLogGroup",
    "logs:CreateLogStream",
    "logs:DeleteLogStream",
    "logs:PutRetentionPolicy",
    "logs:DeleteRetentionPolicy",
    "logs:Describe*",
    "logs:List*",
    "logs:TagLogGroup",
    "logs:UntagLogGroup"
  ],
  "Resource": "*"
}
```

### **7. Secrets Manager (for database URLs, JWT secrets) - OPTIONAL**
```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:CreateSecret",
    "secretsmanager:DeleteSecret",
    "secretsmanager:UpdateSecret",
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret",
    "secretsmanager:ListSecrets",
    "secretsmanager:TagResource",
    "secretsmanager:UntagResource"
  ],
  "Resource": "*"
}
```

### **8. CloudWatch Monitoring & Alarms - OPTIONAL**
```json
{
  "Effect": "Allow",
  "Action": [
    "cloudwatch:PutMetricAlarm",
    "cloudwatch:DeleteAlarms",
    "cloudwatch:DescribeAlarms",
    "cloudwatch:List*",
    "cloudwatch:TagResource",
    "cloudwatch:UntagResource"
  ],
  "Resource": "*"
}
```

### **9. SNS (for production alerts) - OPTIONAL**
```json
{
  "Effect": "Allow",
  "Action": [
    "sns:CreateTopic",
    "sns:DeleteTopic",
    "sns:Subscribe",
    "sns:Unsubscribe",
    "sns:Publish",
    "sns:GetTopicAttributes",
    "sns:SetTopicAttributes",
    "sns:List*",
    "sns:TagResource",
    "sns:UntagResource"
  ],
  "Resource": "*"
}
```

## 🚨 **Critical Services (Must Have)**

1. **EC2/VPC** - ✅ You already added
2. **ECS** - ⚠️ **REQUIRED** for container hosting
3. **ECR** - ⚠️ **REQUIRED** for Docker images  
4. **ELB** - ⚠️ **REQUIRED** for load balancer
5. **IAM** - ⚠️ **REQUIRED** for service roles
6. **CloudWatch Logs** - ⚠️ **REQUIRED** for application logs

## 🎯 **Quick Test Commands**

After adding permissions, test with:

```bash
# Test ECS permissions
aws ecs list-clusters

# Test ECR permissions  
aws ecr describe-repositories

# Test ELB permissions
aws elbv2 describe-load-balancers

# Test IAM permissions
aws iam list-roles --path-prefix /

# Test CloudWatch Logs
aws logs describe-log-groups
```

## ⚡ **Recommended: Use Managed Policy**

**Easiest approach:** Attach `AdministratorAccess` managed policy temporarily for infrastructure deployment, then restrict permissions later for security.

```bash
aws iam attach-user-policy --user-name roxcen-app-dev --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```
