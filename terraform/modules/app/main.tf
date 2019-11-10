resource "google_compute_instance" "app" {
  name         = "reddit-app-terraform"
  machine_type = "f1-micro"
  zone         = "${var.compute_instance_zone}"
  tags         = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }

  metadata {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }
  
  # Connections for provisioning
  connection {
    type  = "ssh"
    user  = "${var.ssh_user}"
    agent = false

    # Path to private key
    private_key = "${file(var.private_key_path)}"
  }

  # Provisioners
  #provisioner "file" {
    
    # Commented since terraform copies file into 
    # .terraform/modules/XXXX/files/puma.service
    # and calls it without adding '/files'
    # source      = "${path.module}/files/puma.service"
    #source      = "${path.module}/puma.service"
    #destination = "/tmp/puma.service"
  #}

  #provisioner "remote-exec" {
    
    # Commented since terraform copies file into 
    # .terraform/modules/XXXX/files/deploy.sh
    # and calls it without adding '/files'
    # script = "${path.module}files/deploy.sh"
    #script = "${path.module}/deploy.sh"
  #}

  #provisioner "remote-exec" {
  #  inline = [
  #    "export DATABASE_URL=${var.db_address}:27017"
  #  ]
  #}
}

# Static IP address
resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
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
