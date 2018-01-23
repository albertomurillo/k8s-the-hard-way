provider "google" {
  credentials = "${file("../account.json")}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "google_compute_network" "default" {
  name                    = "kubernetes-the-hard-way"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name          = "kubernetes"
  ip_cidr_range = "10.240.0.0/24"
  network       = "${google_compute_network.default.self_link}"
}

resource "google_compute_firewall" "internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = "${google_compute_network.default.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "kubernetes-the-hard-way-allow-external"
  network = "${google_compute_network.default.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "default" {
  name = "kubernetes-the-hard-way"
}

resource "google_compute_instance" "controller" {
  count          = 3
  name           = "controller-${count.index}"
  machine_type   = "n1-standard-1"
  zone           = "${var.zone}"
  can_ip_forward = "true"

  boot_disk {
    initialize_params {
      size  = "200"
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.self_link}"
    address    = "10.240.0.1${count.index}"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata {
    pod-cidr = "10.200.${count.index}.0/24"
  }

  tags = ["kubernetes-the-hard-way", "controller"]
}

resource "google_compute_instance" "worker" {
  count          = 3
  name           = "worker-${count.index}"
  machine_type   = "n1-standard-1"
  zone           = "${var.zone}"
  can_ip_forward = "true"

  boot_disk {
    initialize_params {
      size  = "200"
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.default.self_link}"
    address    = "10.240.0.2${count.index}"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata {
    pod-cidr = "10.200.${count.index}.0/24"
  }

  tags = ["kubernetes-the-hard-way", "worker"]
}
