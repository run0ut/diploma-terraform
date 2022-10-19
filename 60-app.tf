################################################################################
# Деплой приложения


# -------------------------------------------------
# Файл для импорта логина и пароля к аккаунту Докера
# в Jenkins Credentials
data "template_file" "app_deployment" {
  template = file("${path.module}/templates/app-deployment.tpl")

  vars = {
    login = "${var.dockerhub_login}"
  }

  depends_on = [
    null_resource.kube_prometheus
  ]
}

# -------------------------------------------------
# Сохранение рендера креденшелов в файл
resource "null_resource" "app_deployment" {

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../02-app/manifests/00-deployment.yml", data.template_file.app_deployment.rendered)
  }

  triggers = {
    template = data.template_file.app_deployment.rendered
  }
}

# -------------------------------------------------
# Jenkinsfile STAGE
data "template_file" "jenkinsfile_stage" {
  template = file("${path.module}/templates/Jenkinsfile.tpl")

  vars = {
    login = "${var.dockerhub_login}"
  }

  depends_on = [
    null_resource.kube_prometheus
  ]
}

# -------------------------------------------------
# Сохранение рендера Jenkinsfile в файл
resource "null_resource" "jenkinsfile_stage" {

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../02-app/Jenkinsfile", data.template_file.jenkinsfile_stage.rendered)
  }

  triggers = {
    template = data.template_file.jenkinsfile_stage.rendered
  }
}


# -------------------------------------------------
# Jenkinsfile PROD
data "template_file" "jenkinsfile_prod" {
  template = file("${path.module}/templates/Jenkinsfile-prod.tpl")

  vars = {
    login = "${var.dockerhub_login}"
  }

  depends_on = [
    null_resource.kube_prometheus
  ]
}

# -------------------------------------------------
# Сохранение рендера Jenkinsfile-prod в файл
resource "null_resource" "jenkinsfile_prod" {

  provisioner "local-exec" {
    command = format("cat <<\"EOF\" > \"%s\"\n%s\nEOF", "../02-app/Jenkinsfile-prod", data.template_file.jenkinsfile_prod.rendered)
  }

  triggers = {
    template = data.template_file.jenkinsfile_prod.rendered
  }
}

# -------------------------------------------------
# Деплой приложения в кластер
resource "null_resource" "app" {
  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply -f ../02-app/manifests/
    EOF
  }


  depends_on = [
    null_resource.app_deployment
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}
