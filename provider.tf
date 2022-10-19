terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.78.2"
    }
  }
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "dimploma-bucket"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "YCAJEHCXpfPQ8N9DEjiVyYi7r"
    secret_key = "YCNi5LHwKGt-b4yjumuQN4wKTLMiCZf1POKEf1fs"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.yandex_cloud_id
  folder_id                = var.yandex_folder_id
  zone                     = var.yandex_compute_default_zone
}
