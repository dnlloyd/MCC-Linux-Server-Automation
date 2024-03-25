# https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-quickstart.html

variable "canvas_students_file" {}
variable "gpg_key" {}
variable "class_name" {}

locals {
  students = jsondecode(file(var.canvas_students_file))
}

resource "aws_iam_user" "student" {
  for_each = local.students

  name          = each.key
  path          = "/"
  force_destroy = true

  tags = {
    "SSMSessionRunAs": "bastion"
  }
}

resource "aws_iam_user_login_profile" "student" {
  for_each = local.students

  user = aws_iam_user.student[each.key].name
  # create GPG key
  # gpg --export dan@lloydconsulting.net | base64
  # /Users/dan/tmp/secure/gpg-lc.pub
  pgp_key = file(var.gpg_key)
}

resource "aws_iam_group" "class" {
  name = var.class_name
}

resource "aws_iam_user_group_membership" "class" {
  for_each = local.students

  user = aws_iam_user.student[each.key].name
  groups = [aws_iam_group.class.name]
}

resource "aws_iam_group_policy_attachment" "ec2ro_attach" {
  group      = aws_iam_group.class.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_group_policy" "session_access" {
  name  = "SSMSessionMgrAccess"
  group = aws_iam_group.class.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:StartSession",
          "ssm:SendCommand"
        ],
        "Resource": [
          "arn:aws:ec2:us-east-1:166865586247:instance/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetConnectionStatus",
          "ssm:Describe*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "ssm:TerminateSession",
            "ssm:ResumeSession"
        ],
        "Resource": [
          "arn:aws:ssm:*:*:session/$${aws:userid}-*"
        ]
      }
    ]
  })
}

# output password | base64 --decode | gpg -d
# tf output -json passwords > /Users/dan/github/dnlloyd/mcc-csis-119-private/passwords.json
output "passwords" {
  value = {
    for k, v in aws_iam_user_login_profile.student : k => v.encrypted_password
  }
}
