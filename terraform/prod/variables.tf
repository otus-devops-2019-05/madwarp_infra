# General section
variable project {
  description = "GCP project indetificator"
}

# Terraform versioning
variable terraform_version {
  description = "Version of Terraform"
  default     = "0.11.7"
}

variable region {
  description = "Project region"

  # Default value
  default = "us-west1"
}

# Ssh section
variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable ssh_user {
  description = "User for ssh sessions during provisioning"
}

variable ssh_source_ip_ranges {
  description = "Allowed IP-address ranges to connect to shh"
  default     = ["0.0.0.0/0"]
}

# Instance section
variable app_disk_image {
  description = "Basic Application image"
}

# Database image name
variable db_disk_image {
  description = "Basic Disk image for reddit db"
  default     = "reddit-db-base"
}

variable compute_instance_zone {
  description = "VM instance zone"
  default     = "us-west1-c"
}
