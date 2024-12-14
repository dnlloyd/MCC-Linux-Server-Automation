# TODO: rename key to iam specific
terraform {
  backend "s3" {
    bucket       = "tf-mcc-linux-server-automation"
    key          = "remote-state-iam.tfstate"
    region       = "us-east-1"
  }
}
