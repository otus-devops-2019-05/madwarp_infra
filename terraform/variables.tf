# General section
variable project {
  description = "GCP project indetificator"
}

variable region {
  description = "Region"

  # Default value
  default = "us-west1-c"
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

# Instance section
variable disk_image {
  description = "Basic Disk image"
}

variable compute_instance_zone {
  description = "VM instance zone"
  default     = "us-west1-c"
}
