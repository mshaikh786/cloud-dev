# Loki S3 Setup Guide for AWS

This guide walks you through setting up AWS S3 buckets for Loki log storage, including IAM configuration for secure access.

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Basic understanding of IAM and S3

## Step 1: Create S3 Buckets

Change the buckets names accordingly

### Create Chunks Bucket
```bash
aws s3api create-bucket --bucket kaust-chunks-loki --region us-east-1
```

### Create Ruler Bucket
```bash
aws s3api create-bucket --bucket kaust-ruler-loki --region us-east-1
```

**Note**: For regions other than `us-east-1`, add the `--create-bucket-configuration` parameter:
```bash
aws s3api create-bucket --bucket kaust-chunks-loki --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
```

### Verify Bucket Creation
```bash
aws s3 ls | grep kaust
```

## Step 2: Create IAM Policy

### Create Policy Document
Create a file named `loki-s3-policy.json`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "LokiStorage",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::kaust-chunks-loki",
                "arn:aws:s3:::kaust-chunks-loki/*",
                "arn:aws:s3:::kaust-ruler-loki",
                "arn:aws:s3:::kaust-ruler-loki/*"
            ]
        }
    ]
}
```

### Create the Policy
```bash
aws iam create-policy --policy-name LokiS3Access --policy-document file://loki-s3-policy.json
```

**Expected Output:**
```json
{
    "Policy": {
        "PolicyName": "LokiS3Access",
        "Arn": "arn:aws:iam::YOUR-ACCOUNT-ID:policy/LokiS3Access",
        "PolicyId": "ANPA...",
        ...
    }
}
```

## Step 3: Create IAM User

### Create User
```bash
aws iam create-user --user-name loki-s3-user
```

### Attach Policy to User
```bash
# Replace YOUR-ACCOUNT-ID with the actual account ID from Step 2 output
aws iam attach-user-policy --user-name loki-s3-user --policy-arn arn:aws:iam::YOUR-ACCOUNT-ID:policy/LokiS3Access
```

### Verify Policy Attachment
```bash
aws iam list-attached-user-policies --user-name loki-s3-user
```

## Step 4: Generate Access Keys

### Create Access Keys
```bash
aws iam create-access-key --user-name loki-s3-user
```

**Expected Output:**
```json
{
    "AccessKey": {
        "UserName": "loki-s3-user",
        "AccessKeyId": "AKIA...",
        "Status": "Active",
        "SecretAccessKey": "your-secret-key",
        "CreateDate": "2025-07-03T16:48:56+00:00"
    }
}
```

**⚠️ Important**: Save these credentials securely. The secret access key is only shown once.


**Note**: Replace `YOUR-ACCOUNT-ID`, `YOUR_ACCESS_KEY_ID`, and `YOUR_SECRET_ACCESS_KEY` with your actual values throughout this guide.