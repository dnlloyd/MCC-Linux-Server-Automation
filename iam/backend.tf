# TODO: rename key to iam specific
terraform {
  backend "s3" {
    bucket       = "tf-mcc-linux-server-automation"
    key          = "remote-state.tfstate"
    region       = "us-east-1"
  }
}
