#
locals {
  control_count_map = {
    stage = 1
    prod  = 1
  }
  worker_count_map = {
    stage = 1
    prod  = 1
  }
}



################################################################################
# Image

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
  # family = "lamp"
  # image_id = "fd81u0g6sfk13ivcfcrm" # lamp-v20220711
}

################################################################################
# Хосты Kubernetes кластера

# ------------------------------------------
# Control nodes
resource "yandex_compute_instance" "control" {
  count    = local.control_count_map[terraform.workspace]
  name     = "diploma-control-${terraform.workspace}-${count.index}"
  hostname = "diploma-control-${terraform.workspace}-${count.index}.local"

  platform_id = "standard-v1"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = "50"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    ipv6      = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# ------------------------------------------
# Worker nodes
resource "yandex_compute_instance" "worker" {
  count    = local.worker_count_map[terraform.workspace]
  name     = "diploma-worker-${terraform.workspace}-${count.index}"
  hostname = "diploma-worker-${terraform.workspace}-${count.index}.local"

  platform_id = "standard-v1"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = "100"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    ipv6      = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
