# Linux Server Automation process

## 1. Set the following environment variables

`CANVAS_STUDENTS_FILE`

A file to store the student data (do not store in source control as this contains PII)

`CANVAS_TOKEN`

Your Canvas API token

`CANVAS_COURSE_ID`

The Canvas course ID

`AWS_IDC_START_URL`

Your AWS Identity Center start URL. This will be used to provide a login link to the students in a Canvas message.

`TF_VAR_canvas_students_file`

A Terraform specific variable to provide the students file path to Terraform. 

`TF_VAR_class_name`

A Terraform specific variable to provide the name of the class to Terraform.

**Examples**

```
export CANVAS_STUDENTS_FILE=/Users/dan/github/dnlloyd/MCC-Linux-Server-Automation/students.json
export CANVAS_TOKEN=<Obfuscated>
export CANVAS_COURSE_ID=16666
export AWS_IDC_START_URL=https://d-9067d70b1d.awsapps.com/start
export TF_VAR_canvas_students_file=$CANVAS_STUDENTS_FILE
export TF_VAR_class_name="csis-119-fall-2024"
```


## 2. Run the user setup script

This script will fetch student info from Canvas for AWS user and Linux user creation. It also creates initial Linux passwords and messages users via Canvas.

```
cd canvas
python user_setup.py
```


## 3. Provision the IAM users

**Prerequisites**

- AWS Identity Center must be created and a permission set provisioned for the account in question. The permission set will have the EC2 read only managed policy and the inline policy (see [iam/AWS-Session-manager.md](iam/AWS-Session-manager.md)) attached to the permission set. 

- Create a group in AWS Identity Center and add ID to IAM Terraform

TODO: Automate Prerequisites above

**Run Terraform**

```
cd iam
terraform init
terraform plan
terraform apply
```


## 4. AWS Systems Manager Session Manager (Optional) 

Perform these steps if you plan to use AWS Systems Manager Session Manager, which gives students the ability to shell into the Linux server via a web browser. Otherwise, students will need to use an SSH client from their local machine.

[iam/AWS-Session-manager.md](iam/AWS-Session-manager.md)


## 5. Provision the Linux server

**Run Terraform**

```
cd ec2
terraform init
terraform plan
terraform apply
```
