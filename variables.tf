################################################################################
# Yandex IDs
variable "yandex_cloud_id" {
  default = "ID ОБЛАКА НЕ ЗАДАН В .auto.tfvars"
}

variable "yandex_folder_id" {
  default = "ID ПАПКИ НЕ ЗАДАН В .auto.tfvars"
}

variable "yandex_compute_default_zone" {
  default = "ru-central1-a"
}

################################################################################
# DockerHub
variable "dockerhub_login" {
  default = "ЛОГИН НЕ ЗАДАН В .auto.tfvars"
}

variable "dockerhub_password" {
  default   = "ПАРОЛЬ НЕ ЗАДАН В .auto.tfvars"
  sensitive = true
}

################################################################################
# GitHub
variable "github_personal_access_token" {
  default   = "ТОКЕН НЕ ЗАДАН В .auto.tfvars"
  sensitive = true
}

variable "github_webhook_secret" {
  default = "diplomasecret"
}

variable "github_login" {
  default = "ЛОГИН НЕ ЗАДАН В .auto.tfvars"
}
