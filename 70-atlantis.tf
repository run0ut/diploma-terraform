################################################################################
# Деплой Atlantis

# -------------------------------------------------
# Statefulset со внешним IP web-интерфейса Atlantis
# чтобы на Github работал переход в "Details"
data "template_file" "atlantis_manifest" {
  template = file("${path.module}/templates/atlantis_statefulset.tpl")

  vars = {
    atlantis_ip = "${yandex_compute_instance.control.0.network_interface.0.nat_ip_address}"
    login = "${var.github_login}"
  }

  depends_on = [
    null_resource.app
  ]
}

# -------------------------------------------------
# Сохранение рендера манифеста в файл
resource "null_resource" "atlantis_manifest" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../04-atlantis/manifests/10-satatefulSet.yml", data.template_file.atlantis_manifest.rendered)
  }

  triggers = {
    template = data.template_file.kubectl.rendered
  }
}

# -------------------------------------------------
# Серверный конфиг Атлантис
data "template_file" "atlantis_repo_config" {
  template = file("${path.module}/templates/server.tpl")

  vars = {
    login = "${var.github_login}"
  }

  depends_on = [
    null_resource.app
  ]
}

# -------------------------------------------------
# Сохранение рендера конфига в файл
resource "null_resource" "atlantis_repo_config" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../01-yandex/server.yaml", data.template_file.atlantis_repo_config.rendered)
  }

  triggers = {
    template = data.template_file.kubectl.rendered
  }
}

# -------------------------------------------------
# Создание configmap для монтирования в Атлантис
# - ssh закрытый и открый ключи для создания инстансов и доступа на сервера
# - .terraformrc нужен для РФ, т.к. Терраформ реджистри блокирует обращения из России
# - .auto.tfvars с некоторыми параметрами провайдера Яндекс, чтобы не мержить в репозиторий
# - key.json - ключ сервис-аккаунта Яндекса с правами на работу в облаке, тоже чтобы не мержить
# - server.yaml - конфигурация сервера, чтобы работал atlantis.yaml из репозитория 
resource "null_resource" "atlantis_configmaps" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} \
      create configmap atlantis-files \
        --from-file=ssh=$HOME/.ssh/id_rsa \
        --from-file=ssh-pub=$HOME/.ssh/id_rsa.pub \
        --from-file=terraformrc=.terraformrc \
        --from-file=auto-tfvars=.auto.tfvars \
        --from-file=key-json=key.json \
        --from-file=server-config=server.yaml
    EOF
  }

  depends_on = [
    null_resource.atlantis_manifest,
    null_resource.atlantis_repo_config
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# -------------------------------------------------
# Деплой Atlantis в кластер
# Первая команда добавляет configmap с токенами GitHub 
# Вторая деплоит Атлантис
resource "null_resource" "atlantis" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} create secret generic atlantis-vcs --from-literal=token=${var.github_personal_access_token} --from-literal=webhook-secret=${var.github_webhook_secret}
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply -f ../04-atlantis/manifests/
    EOF
  }


  depends_on = [
    null_resource.atlantis_manifest
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# -------------------------------------------------
# Настройка веб-хука репозитория для обращения к Atlantis

locals {
  atlantis_ip = yandex_compute_instance.control.0.network_interface.0.nat_ip_address
}

resource "null_resource" "terraform_repo" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      ##########################################################################
      ### Создание репозитория
      hook_id=''
      repo_id=''
      repo_name=diploma-terraform
      repo_name_git=diploma-terraform.git
      token=${var.github_personal_access_token}
      # Проверка, может репозиторий уже есть
      repo_id=$(curl -sS\
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        https://api.github.com/repos/${var.github_login}/$repo_name | jq .id)
      if [[ "$repo_id" == "null" ]]; then
        curl -sS \
          -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $token" \
          https://api.github.com/user/repos \
          -d '{"name":"'$repo_name'","description":"Netology DevOps cource diploma, terraform manifests","homepage":"https://github.com","private":false,"is_template":false}'
      fi
      ##########################################################################
      ### Пуш манифестов в репозиторий
      is_initialized=$(git init | grep -c 'Reinitialized existing')
      git add *tf {ansible,kubeconfig}/README.md templates/* README.md *yaml --force
      git add .gitignore && git add .terraformrc
      [[ "$is_initialized" == "0" ]] && git commit -m "Первый коммит" || git commit -m "terraform apply commit"
      git branch -M main
      git remote remove origin
      git remote add origin git@github.com:${var.github_login}/$repo_name_git
      git config remote.origin.push HEAD
      git push --set-upstream origin main
      ##########################################################################
      ### Настройка хука
      # Получить данные о хуках репозитория
      hook_id=$(curl -sS \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        https://api.github.com/repos/${var.github_login}/$repo_name/hooks | jq .[0].id)
      if [[ "$hook_id" == "null" ]]; then
        # Если хука нет, создать
        echo "Create hook"
        curl -sS \
          -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $token" \
          https://api.github.com/repos/${var.github_login}/$repo_name/hooks \
          -d '{"name":"web","active":true,"events":["push","pull_request","pull_request_review","issue_comment"],"config":{"url":"http://${local.atlantis_ip}:30141/events","content_type":"json","insecure_ssl":"0","secret":"diplomasecret"}}'
      else
        # Если хук есть, обновить URL
        echo "Update hook"
        curl -sS \
          -X PATCH \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $token" \
          https://api.github.com/repos/${var.github_login}/$repo_name/hooks/$hook_id \
          -d '{"name":"web","active":true,"events":["push","pull_request","pull_request_review","issue_comment"],"config":{"url":"http://${local.atlantis_ip}:30141/events","content_type":"json","insecure_ssl":"0","secret":"diplomasecret"}}'
      fi
    EOF
    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }

  depends_on = [
    null_resource.atlantis
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}
