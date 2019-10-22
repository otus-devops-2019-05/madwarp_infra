terraform {
  # Version of terraform
  required_version = "0.11.7"
}

provider "google" {
  # Version of provider
  version = "2.0.0"

  # project ID
  project = "${var.project}"
  region  = "${var.region}"
}

# Global project metadata
resource "google_compute_project_metadata" "default" {
  metadata = {
    # Path to public key
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}\nappuser2:${file(var.public_key_path)}"
  }
}


resource "google_compute_instance" "app" {
  name         = "reddit-app-terraform"
  machine_type = "f1-micro"
  zone         = "${var.compute_instance_zone}"

  # Tag for firewall
  tags = ["reddit-app"]

  metadata {
    # Path to public key
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  # Boot disk definition
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  # Network interface definition
  network_interface {
    # Network attach to
    network = "default"

    # Use ephemeral IP 
    access_config {}
  }

  # Connections for provisioning
  connection {
    type  = "ssh"
    user  = "${var.ssh_user}"
    agent = false

    # путь до приватного ключа
    private_key = "${file(var.private_key_path)}"
  }

  # Provisioners
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

#Firewall rules
resource "google_compute_firewall" "firewall_reddit_puma" {
  name = "allow-reddit-9292"

  # Network name
  network = "default"

  # Rules
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  # Address pool
  source_ranges = ["0.0.0.0/0"]

  # Tags
  target_tags = ["reddit-app"]
}
