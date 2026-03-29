

````md
# Jenkins Project Arma

This project uses Jenkins, Terraform, GitHub webhooks, and AWS S3 to automatically upload files from this repository into an S3 bucket after code is pushed to GitHub.

## What this project does

Once Jenkins is running on an EC2 instance, this repo can be connected to Jenkins so that:

1. You push changes from your local machine to GitHub
2. GitHub sends a webhook to Jenkins
3. Jenkins pulls the latest code from this repository
4. Jenkins runs Terraform from the `Week-27` directory
5. Terraform creates or updates the S3 bucket and uploads the files in this repo to S3

---

## Repository structure

```text
Jenkins-Project-Arma/
├── Jenkinsfile
└── Week-27/
    ├── 1-auth.tf
    ├── 2-main.tf
    ├── README.md
    ├── Armageddon-Proof/
    └── Jenkins-Proof/
````

---

## Prerequisites

Before using this repo, make sure you already have:

* An AWS account
* A running EC2 instance with Jenkins installed
* Security group rules allowing:

  * port 22 for SSH
  * port 8080 for Jenkins
* Git installed on the Jenkins server
* Terraform installed on the Jenkins server
* AWS CLI installed on the Jenkins server
* A GitHub account and access to this repository

---

## Step 1: Connect to your Jenkins EC2 instance

SSH into the EC2 instance where Jenkins is installed.

Example:

```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

If you are using Ubuntu, the username may be:

```bash
ubuntu
```

---

## Step 2: Verify Jenkins is running

Check Jenkins service status:

```bash
sudo systemctl status jenkins
```

If needed, start and enable it:

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

Open Jenkins in the browser:

```text
http://YOUR_EC2_PUBLIC_IP:8080
```

---

## Step 3: Install required tools on the Jenkins EC2 server

### Install Git

Amazon Linux:

```bash
sudo yum install git -y
```

Ubuntu:

```bash
sudo apt update
sudo apt install git -y
```

### Install Terraform

Amazon Linux:

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y
```

Ubuntu:

```bash
sudo apt update && sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform -y
```

### Install AWS CLI

Amazon Linux:

```bash
sudo yum install aws-cli -y
```

Ubuntu:

```bash
sudo apt update
sudo apt install awscli -y
```

### Verify installations

```bash
git --version
terraform -version
aws --version
```

---

## Step 4: Create the S3 bucket for Terraform state

This repo uses a remote Terraform backend in S3.

The backend configuration in `Week-27/1-auth.tf` expects this bucket:

```text
jenkins-tf-state-z1
```

Create it before running the pipeline:

```bash
aws s3 mb s3://jenkins-tf-state-z1 --region us-east-1
```

Optional but recommended: enable versioning on the state bucket:

```bash
aws s3api put-bucket-versioning \
  --bucket jenkins-tf-state-z1 \
  --versioning-configuration Status=Enabled
```

---

## Step 5: Create AWS credentials for Jenkins

Jenkins needs AWS credentials so Terraform can create S3 resources.

### In AWS

Create an IAM user for Jenkins or use an existing IAM user with permissions to manage:

* S3 buckets
* S3 objects
* Terraform state bucket access

For testing, broad S3 permissions may work, but least-privilege access is recommended for real environments.

### In Jenkins

1. Open Jenkins
2. Go to:

```text
Manage Jenkins -> Credentials
```

3. Add a new credential
4. Choose:

```text
Kind: AWS Credentials
```

5. Set the credential ID to:

```text
Jenkins
```

This is important because the `Jenkinsfile` uses:

```groovy
credentialsId: 'Jenkins'
```

If you use a different credential ID in Jenkins, update the `Jenkinsfile` to match.

---

## Step 6: Create the Jenkins pipeline job

1. In Jenkins, click:

```text
New Item
```

2. Enter a name such as:

```text
Jenkins-Armageddon-Pipeline
```

3. Select:

```text
Pipeline
```

4. Click OK

### Configure the job

Under the Pipeline section, set:

```text
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/JGordonHall/Jenkins-Project-Arma.git
Branch Specifier: */main
Script Path: Jenkinsfile
```

Save the job.

---

## Step 7: Configure the GitHub webhook

In GitHub:

1. Open this repository
2. Go to:

```text
Settings -> Webhooks
```

3. Click:

```text
Add webhook
```

4. Use the following settings:

### Payload URL

```text
http://YOUR_EC2_PUBLIC_IP:8080/github-webhook/
```

### Content type

```text
application/json
```

### Events

```text
Just the push event
```

### Active

Make sure the webhook is enabled.

Save the webhook.

---

## Step 8: Make sure the Jenkins EC2 security group allows webhook traffic

Your EC2 security group must allow inbound traffic on:

```text
TCP 8080
```

If GitHub cannot reach Jenkins on port 8080, the webhook will fail.

---

## Step 9: Review the Terraform configuration in this repo

This repo currently uses:

* `Week-27/1-auth.tf` for:

  * AWS provider
  * remote backend in S3

* `Week-27/2-main.tf` for:

  * S3 bucket creation
  * uploading files from:

    * `Armageddon-Proof`
    * `Jenkins-Proof`

Before running the pipeline, review:

### Backend bucket

In `Week-27/1-auth.tf`:

```hcl
backend "s3" {
  bucket = "jenkins-tf-state-z1"
  key    = "jenkins/terraform.tfstate"
  region = "us-east-1"
  encrypt = true
}
```

Make sure this bucket exists.

### Region

This repo uses:

```hcl
region = "us-east-1"
```

Make sure your AWS resources and credentials are intended for that region.

### Folder names

Folder names must match exactly.

For example:

```text
Jenkins-Proof
```

is different from:

```text
Jenkins_Proof
```

Terraform source paths are case-sensitive and character-sensitive.

---

## Step 10: Push a change to trigger the pipeline

From your local machine:

```bash
git add .
git commit -m "Trigger Jenkins pipeline"
git push origin main
```

This should trigger the full flow:

1. GitHub receives the push
2. GitHub sends the webhook to Jenkins
3. Jenkins starts the pipeline
4. Jenkins checks out the repo
5. Jenkins runs:

   * `terraform init`
   * `terraform fmt -check -recursive`
   * `terraform validate`
   * `terraform plan -out=tfplan`
   * `terraform apply -auto-approve tfplan`
6. Terraform creates or updates the S3 bucket and uploads the files

---

## Step 11: Verify the build in Jenkins

After pushing code:

1. Open Jenkins
2. Open the pipeline job
3. Click the latest build
4. Open Console Output

You should see the pipeline stages run in order.

If successful, Jenkins will show that Terraform completed and the S3 resources were applied.

---

## Step 12: Verify files in S3

Use the AWS CLI:

```bash
aws s3 ls
```

Find the bucket created by Terraform.

Then list its contents:

```bash
aws s3 ls s3://YOUR_BUCKET_NAME --recursive
```

You should see files uploaded from:

* `Armageddon-Proof/`
* `Jenkins-Proof/`

---

## Optional: Run destroy from Jenkins

The root `Jenkinsfile` includes a boolean parameter:

```text
DESTROY_AFTER_APPLY
```

If you enable this when starting the job manually, Jenkins can run:

```bash
terraform destroy -auto-approve
```

after the apply step.

Use this carefully because it will remove the Terraform-managed resources.

---

## Troubleshooting

## Jenkins cannot find the Jenkinsfile

Make sure the pipeline is configured with:

```text
Script Path: Jenkinsfile
```

and not a subfolder path.

## Terraform backend errors

Make sure the S3 state bucket exists:

```text
jenkins-tf-state-z1
```

and that the Jenkins AWS credentials can access it.

## AWS credential errors

Make sure the Jenkins credential ID is:

```text
Jenkins
```

or update the `Jenkinsfile` if you used a different ID.

## Webhook does not trigger Jenkins

Check:

* Jenkins is reachable on port 8080
* EC2 security group allows inbound 8080
* GitHub webhook URL is correct
* Jenkins has GitHub webhook support enabled

## File path errors

Make sure file paths in Terraform match the real repo folder names exactly.

Example:

```text
Jenkins-Proof
```

not:

```text
Jenkins_Proof
```

---

## Useful commands

### Check Jenkins logs

```bash
sudo journalctl -u jenkins -f
```

### Test Terraform manually on the Jenkins server

```bash
cd /var/lib/jenkins/workspace/Jenkins-Armageddon-Pipeline/Week-27
terraform init
terraform validate
terraform plan
```

### Check AWS identity being used

```bash
aws sts get-caller-identity
```

---

## Notes

This project currently uses Terraform to upload files to S3 through `aws_s3_object` resources. That works for this repo and demonstrates end-to-end automation clearly.

For larger-scale file syncing or frequently changing folders, a future improvement would be to keep Terraform only for infrastructure and use:

```bash
aws s3 sync
```

inside Jenkins for file uploads.

---

## Summary

This repo demonstrates how to:

* run Jenkins on EC2
* connect Jenkins to GitHub
* trigger Jenkins builds with GitHub webhooks
* use Terraform in Jenkins
* store Terraform state in S3
* create an S3 bucket
* upload files from the repo to S3 automatically after each push

```

If you want, I can also turn this into a shorter, more polished portfolio-style README with cleaner sections and badges.
::contentReference[oaicite:1]{index=1}
```

[1]: https://github.com/JGordonHall/Jenkins-Project-Arma "GitHub - JGordonHall/Jenkins-Project-Arma · GitHub"
