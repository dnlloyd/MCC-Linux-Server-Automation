# variable "canvas_students_passwords_file" {}
variable "canvas_students_file" {}
variable "class_name" {}

locals {
  students = jsondecode(file(var.canvas_students_file))
  vpc_id = "vpc-2f83f048"
  dns_zone_id = "Z04335951B2PXZNYP06R"
}

resource "aws_security_group" "linux_server" {
  name        = "${var.class_name}-linux"
  description = "Public access to Linux server"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.class_name}-linux" }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["137112412989"]

  filter {
    name = "name"
    values = ["al2023-ami-2023.6.20241010.0-kernel-6.1-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_instance_profile" "ssm" {
  name = "SSMManagedEc2"
  role = aws_iam_role.ssm.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm" {
  name               = "SSMManagedEc2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

resource "aws_instance" "linux" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  iam_instance_profile = "SSMInstanceProfile"
  key_name = "aws-personal"
  vpc_security_group_ids = [aws_security_group.linux_server.id]

  tags = {
    Name = "${var.class_name}-linux"
  }

  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts
  # cat /var/log/cloud-init-output.log
  # /var/lib/cloud/instances/i-XXX/user-data.txt
  user_data = base64encode(templatefile("init-scripts/provision-users.tftpl", {students = local.students}))
}

resource "aws_route53_record" "www" {
  zone_id = local.dns_zone_id
  name    = "mcc.daniel-lloyd.net"
  type    = "A"
  ttl     = 300
  records = [aws_instance.linux.public_ip]
}

output "public_ip" {
  value = aws_instance.linux.public_ip
}
