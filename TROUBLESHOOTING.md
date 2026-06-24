# Troubleshooting Guide

Common issues and fixes encountered during setup and deployment.

---

## 1. AWS Credentials Not Found in Jenkins

**Error:**
```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Fix:**
- Go to Jenkins → Manage Jenkins → Credentials
- Add your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as Secret Text credentials
- Make sure the credential IDs match exactly what is used in the Jenkinsfile

---

## 2. S3 Bucket Access Denied During Deploy

**Error:**
```
An error occurred (AccessDenied) when calling the PutObject operation
```

**Fix:**
- Verify the IAM user has `s3:PutObject`, `s3:DeleteObject`, and `s3:ListBucket` permissions on the bucket
- Run `terraform apply` again to re-apply the correct IAM policy
- Check that `S3_BUCKET_NAME` in Jenkins matches the actual bucket name created by Terraform

---

## 3. CloudFront Cache Not Clearing After Deploy

**Symptom:** Old version of the site still showing after a successful deploy

**Fix:**
- The Jenkinsfile runs an invalidation automatically: `aws cloudfront create-invalidation --paths "/*"`
- If it still shows old content, wait 2-3 minutes for edge cache propagation
- Confirm `CLOUDFRONT_DISTRIBUTION_ID` is set correctly in Jenkins credentials

---

## 4. Terraform State Lock Error

**Error:**
```
Error acquiring the state lock
```

**Fix:**
- Another process may have exited without releasing the lock
- Run: `terraform force-unlock <LOCK_ID>` (lock ID is shown in the error message)
- Only do this if you are sure no other `terraform apply` is running

---

## 5. Jenkins Pipeline Fails at npm install Stage

**Error:**
```
npm: command not found
```

**Fix:**
- Node.js is not installed on the Jenkins agent
- SSH into the Jenkins EC2 instance and run the setup script:
  ```bash
  bash jenkins/jenkins-setup.sh
  ```
- Or install manually: `sudo apt install nodejs npm -y`
