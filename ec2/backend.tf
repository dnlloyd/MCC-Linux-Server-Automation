terraform {
  backend "s3" {
    bucket       = "tf-mcc-linux-server-automation"
    key          = "remote-state-ec2.tfstate"
    region       = "us-east-1"
  }
}
