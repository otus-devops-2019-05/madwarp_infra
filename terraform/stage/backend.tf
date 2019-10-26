#data "terraform_remote_state" "stage" {
#  backend = "gcs"
#  config = {
#    bucket  = "storage-bucket-terraform-stage"
#    prefix  = "stage"
#  }
#}

terraform {
  backend "gcs" {
    bucket = "storage-bucket-terraform-stage"
    prefix = "stage"
  }
}
