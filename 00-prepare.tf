################################################################################
# Загрузка kubespray, установка зависимостей, подгтовка папки для инвентаризации
resource "null_resource" "git_clone" {
  provisioner "local-exec" {
    command = "if [ ! -d 'kubespray' ] ; then git clone https://github.com/kubernetes-sigs/kubespray.git; fi"
  }
}

resource "null_resource" "requirements" {
  provisioner "local-exec" {
    command = "pip3 install -r kubespray/requirements.txt"
  }

  depends_on = [
    null_resource.git_clone
  ]
}

resource "null_resource" "folder" {
  provisioner "local-exec" {
    command = "cp -rfp kubespray/inventory/sample kubespray/inventory/diplomacluster"
  }

  depends_on = [
    null_resource.requirements
  ]
}