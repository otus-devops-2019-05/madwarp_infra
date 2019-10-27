resource "google_compute_instance" "db" {
  name         = "reddit-db"
  machine_type = "f1-micro"
  zone         = "${var.compute_instance_zone}"
  tags         = ["reddit-db"]

  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }

  network_interface {
    network = "default"
    access_config = {}
  }

  metadata {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }
}

#Firewall rules
resource "google_compute_firewall" "firewall_mongo_db" {
  name = "allow-mongo-default"

  # Network name
  network = "default"

  # Rules
  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  # Address pool
  source_ranges = ["0.0.0.0/0"]

  # Tags
  target_tags = ["reddit-db"]
  source_tags = ["reddit-app"]
}

