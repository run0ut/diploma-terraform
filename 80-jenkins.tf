################################################################################
# Деплой Jenkins

# -------------------------------------------------
# Создание репозитория с приложением и загрузка кода
resource "null_resource" "app_repo" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      ##########################################################################
      ### Создание репозитория
      hook_id=''
      repo_id=''
      repo_name=diploma-test-app
      repo_name_git=diploma-test-app.git
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
          -d '{"name":"'$repo_name'","description":"Netology DevOps cource diploma, test application","homepage":"https://github.com","private":false,"is_template":false}'
      fi
      ##########################################################################
      ### Пуш манифестов в репозиторий
      cd ../02-app
      is_initialized=$(git init | grep -c 'Reinitialized existing')
      git add . {manifests,static-html-directory}/. --force
      [[ "$is_initialized" == "0" ]] && git commit -m'Первый коммит' || git commit -m'terraform apply commit'
      git branch -M main
      git remote remove origin
      git remote add origin git@github.com:${var.github_login}/$repo_name_git
      git config remote.origin.push HEAD
      git push --set-upstream origin main
      cd -
    EOF
    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }

  depends_on = [
    null_resource.kube_prometheus
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# -------------------------------------------------
# Формирование задач Jenkins по шаблону, со ссылкой на репозиторий тестового приложения
data "template_file" "diploma_test_app_stage_config" {
  template = file("${path.module}/templates/diploma-test-app-stage-config.tpl")

  vars = {
    login = "${var.github_login}"
  }

  depends_on = [
    null_resource.app_repo
  ]
}

# -------------------------------------------------
# Сохранение рендера шаблона в файл
resource "null_resource" "diploma_test_app_stage_config" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../05-jenkins/jobs/diploma-test-app-stage/config.xml", data.template_file.diploma_test_app_stage_config.rendered)
  }

  triggers = {
    template = data.template_file.diploma_test_app_stage_config.rendered
  }
}

# -------------------------------------------------
# Формирование задач Jenkins по шаблону, со ссылкой на репозиторий тестового приложения
data "template_file" "diploma_test_app_prod_config" {
  template = file("${path.module}/templates/diploma-test-app-stage-config.tpl")

  vars = {
    login = "${var.github_login}"
  }

  depends_on = [
    null_resource.diploma_test_app_stage_config
  ]
}

# -------------------------------------------------
# Сохранение рендера шаблона в файл
resource "null_resource" "diploma_test_app_prod_config" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../05-jenkins/jobs/diploma-test-app-stage/config.xml", data.template_file.diploma_test_app_prod_config.rendered)
  }

  triggers = {
    template = data.template_file.diploma_test_app_prod_config.rendered
  }
}

# -------------------------------------------------
# Файл для импорта логина и пароля к аккаунту Докера
# в Jenkins Credentials
data "template_file" "jenkins_credentials" {
  template = file("${path.module}/templates/exported-credentials.tpl")

  vars = {
    login    = "${var.dockerhub_login}"
    password = "${var.dockerhub_password}"
  }

  depends_on = [
    null_resource.kube_prometheus
  ]
}

# -------------------------------------------------
# Сохранение рендера креденшелов в файл
resource "null_resource" "jenkins_credentials" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../05-jenkins/exported-credentials.xml", data.template_file.jenkins_credentials.rendered)
  }

  triggers = {
    template = data.template_file.jenkins_credentials.rendered
  }
}

# -------------------------------------------------
# Конфигурации для провижена Jenkins
resource "null_resource" "jenkins_configmaps" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} \
      create configmap jenkins-files \
        --from-file=credentials=../05-jenkins/exported-credentials.xml \
        --from-file=diploma-test-app-stage=../05-jenkins/jobs/diploma-test-app-stage/config.xml \
        --from-file=diploma-test-app-prod=../05-jenkins/jobs/diploma-test-app-prod/config.xml \
        --from-file=kubeconfig=kubeconfig/config-prod
    EOF
  }

  depends_on = [
    null_resource.jenkins_credentials
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# -------------------------------------------------
# Деплой Jenkins в кластер
resource "null_resource" "jenkins" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply -f ../05-jenkins/manifests/
    EOF
  }


  depends_on = [
    null_resource.jenkins_configmaps
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# -------------------------------------------------
# Создание репозитория с приложением и загрузка кода
resource "null_resource" "add_tag" {
  count = (terraform.workspace == "prod") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      cd ../02-app
      tag_n=$(git tag --sort version:refname | tail -1 | cut -d . -f 3)
      [[ "$tag_n" == "" ]] && tag_n=0
      date +%s > dummy
      git add dummy
      tag_n=$((tag_n+1))
      git commit -m "tag $tag_n"
      git tag v0.0.$tag_n
      git push --tags origin main
      cd -
    EOF
    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }

  depends_on = [
    null_resource.jenkins
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}
