# Ssh section
variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable ssh_user {
  description = "User for ssh sessions during provisioning"
}

# Database image name
variable db_disk_image {
description = "Basic Disk image for reddit db"
default = "reddit-db-base"
}

variable compute_instance_zone {
  description = "VM instance zone"
  default     = "us-west1-c"
}

