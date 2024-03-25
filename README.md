# Linux Server Automation process

## 1. Set the following environment variables

A file to store the student data (outside of source control as this contains PII)

`CANVAS_STUDENTS_FILE`

Your Canvas API token

`CANVAS_TOKEN`

The Canvas course ID

`CANVAS_COURSE_ID`

Your AWS account ID. This will be used to provide a login link to the students in a Canvas message

`AWS_ACCOUNT_ID`

A file to store the student's encrypted passwords (outside of source control as this contains PII)

`CANVAS_STUDENT_PASSWORDS_FILE`

A file to store the student's unencrypted passwords (outside of source control as this contains PII)

`CANVAS_STUDENT_PASSWORDS_FILE_PLAIN_TEXT`

Sometimes invalid passwords are created, and until I fix this bug I need to manually provision these users. This script gets automatically generated if invalid passwords are used.

*TODO: fix this bug*

`MANUAL_USER_PROVISION_SCRIPT`

Examples

```
export CANVAS_STUDENTS_FILE="/Users/dan/tmp/mcc-linux/students.json"
export CANVAS_TOKEN="<Obfuscated>"
export CANVAS_COURSE_ID="11905"
export AWS_ACCOUNT_ID="166865586247"
export CANVAS_STUDENT_PASSWORDS_FILE="/Users/dan/tmp/mcc-linux/passwords.json"
export CANVAS_STUDENT_PASSWORDS_FILE_PLAIN_TEXT="/Users/dan/tmp/mcc-linux/passwords-plain-text.json"
export MANUAL_USER_PROVISION_SCRIPT="/Users/dan/tmp/mcc-linux/manual_user_provisions.sh"
```

## 2. Get users from Canvas and write to file

```
export C_MODE="write"
```

Run the [canvas/get-users.py](canvas/get-users.py) script

## 3. Provision the IAM users

Install GNU PGP and create key

```
brew install gnupg
gpg --export some-user@some-sub-domain.some-domain | base64
```

Set the following environment variables

TF variable for the GPG public key location

```
TF_VAR_gpg_key
```

TF variable for the students file from step 1
```
TF_VAR_canvas_students_file
```

TF variable for the name of the class
```
TF_VAR_class_name
```

Examples

```
export TF_VAR_gpg_key="/Users/dan/tmp/secure/gpg-lc.pub"
export TF_VAR_canvas_students_file=$CANVAS_STUDENTS_FILE
export TF_VAR_class_name="csis-152"
```

Run Terraform

```
cd iam
terraform init
terraform plan
terraform apply
```

## AWS Systems Manager Session Manager (Optional) 

Perform these steps if you plan to use AWS Systems Manager Session Manager, which gives students the ability to shell into the Linux server via a web browser. Otherwise, students will need to use an SSH client from their local machine.

[iam/AWS-Session-manager.md](iam/AWS-Session-manager.md)

## 4. Write encrypted passwords to passwords file

*TODO: Automate this step*

```
tf output -json passwords > $CANVAS_STUDENT_PASSWORDS_FILE
```

## 5. Decrypt and send passwords to students

```
export C_MODE="send"
```

Run the [canvas/get-users.py](canvas/get-users.py) script

## 6. Run terraform to provision EC2 instance

Set the following environment variables

TF variable for the path to the students plain text passwords file

```
TF_VAR_canvas_students_passwords_file
```

example

```
export TF_VAR_canvas_students_passwords_file="/Users/dan/tmp/mcc-linux/passwords-plain-text.json"
```

```
cd ec2
terraform init
terraform plan
terraform apply
```

## 7. Manually provision users that receive invalid passwords

*TODO: fix this bug*

On the Linux server, execute the manual user provision script set at `$MANUAL_USER_PROVISION_SCRIPT`
