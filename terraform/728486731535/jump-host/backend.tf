terraform {
  backend "s3" {
    bucket  = "terraform-state-docc"
    key     = "rke2-jump-host/terraform.tfstate"
    region  = "eu-central-1" # Change to your preferred region
    encrypt = true
    # S3 state locking (newer approach)
    dynamodb_table = null # Set to null to disable DynamoDB

    # Enable S3 object locking for state files
    use_lockfile = true

  }
}
