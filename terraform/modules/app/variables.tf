
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
  description = "Path to the private key used for provisioning"
}

variable ssh_user {
  description = "User for ssh sessions during provisioning"
}

# Instance section
variable app_disk_image {
  description = "Basic Application image"
}

variable compute_instance_zone {
  description = "VM instance zone"
  default     = "us-west1-c"
}

# MongoDB environment variable
variable db_address {
  description = "Environment variable DATABASE_URL for MongoDB connection"
  default = "localhost"
}
