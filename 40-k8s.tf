################################################################################
# Время, пока стартуют ноды. 50 секунд обычно хватает, даже с запасом

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 50"
  }

  depends_on = [
    null_resource.inventories
  ]
}

################################################################################
# supplementary_addresses_in_ssl_keys

data "template_file" "supplementary_addresses_in_ssl_keys" {
  template = file("${path.module}/templates/supplementary_addresses_in_ssl_keys.tpl")

  vars = {
    workspace = "${terraform.workspace}"
  }

  depends_on = [
    null_resource.wait
  ]
}

resource "null_resource" "supplementary_addresses_in_ssl_keys_playbook" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.supplementary_addresses_in_ssl_keys.rendered}' > ansible/supplementary_addresses_in_ssl_keys-${terraform.workspace}.yml"
  }

  triggers = {
    template = data.template_file.supplementary_addresses_in_ssl_keys.rendered
  }
}

resource "null_resource" "public_access" {
  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i kubespray/inventory/diplomacluster/inventory-${terraform.workspace}.ini ansible/supplementary_addresses_in_ssl_keys-${terraform.workspace}.yml -b -v"
  }

  depends_on = [
    null_resource.supplementary_addresses_in_ssl_keys_playbook
  ]
}

################################################################################
# kubespray

resource "null_resource" "kubespray" {
  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i kubespray/inventory/diplomacluster/inventory-${terraform.workspace}.ini kubespray/cluster.yml -b -v"
  }

  depends_on = [
    null_resource.public_access
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

################################################################################
# kubectl

data "template_file" "kubectl" {
  template = file("${path.module}/templates/playbook.tpl")

  vars = {
    workspace = "${terraform.workspace}"
  }

  depends_on = [
    null_resource.kubespray
  ]
}

resource "null_resource" "kubectl_playbook" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.kubectl.rendered}' > ansible/playbook-${terraform.workspace}.yml"
  }

  triggers = {
    template = data.template_file.kubectl.rendered
  }
}

resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i kubespray/inventory/diplomacluster/inventory-${terraform.workspace}.ini ansible/playbook-${terraform.workspace}.yml -b -v"
  }

  depends_on = [
    null_resource.kubectl_playbook
  ]

  triggers = {
    cluster_instance_ids = join(",", null_resource.inventories.*.id)
  }
}