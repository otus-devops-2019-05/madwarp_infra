terraform {
  # Version of terraform
  required_version = "0.11.11"
}

provider "google" {
  # Version of provider
  version = "2.0.0"

  # project ID
  project = "${var.project}"
  region  = "${var.region}"
}

# Modules
module "app" {
  source                = "../modules/app"
  public_key_path       = "${var.public_key_path}"
  private_key_path      = "${var.private_key_path}"
  compute_instance_zone = "${var.compute_instance_zone}"
  app_disk_image        = "${var.app_disk_image}"
  ssh_user              = "${var.ssh_user}"
}

module "db" {
  source                = "../modules/db"
  public_key_path       = "${var.public_key_path}"
  compute_instance_zone = "${var.compute_instance_zone}"
  db_disk_image         = "${var.db_disk_image}"
  ssh_user              = "${var.ssh_user}"
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = "${var.ssh_source_ip_ranges}"
}
