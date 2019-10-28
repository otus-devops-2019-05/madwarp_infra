
terraform {
  # Google Cloud Storage backend
  backend "gcs" {
    # The name of bucket
    bucket = "storage-bucket-terraform-prod"
    # Parent directory of default.tfstate
    prefix = "prod"
  }
}
