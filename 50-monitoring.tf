################################################################################
# Monitoring

# ---------------------------
# Deploy kube-prometheus
resource "null_resource" "kube_prometheus" {
  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply --server-side -f ../03-monitoring/kube-prometheus/manifests/setup
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} wait \
        --for condition=Established \
        --all CustomResourceDefinition \
        --namespace=monitoring
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply -f ../03-monitoring/kube-prometheus/manifests/
    EOF
  }


  depends_on = [
    null_resource.kubectl
  ]

  triggers = {
    cluster_instance_ids = join(",", [join(",", yandex_compute_instance.control.*.id), join(",", yandex_compute_instance.worker.*.id)])
  }
}

# ---------------------------
# Grafana access on public IP
resource "null_resource" "grafana_public" {
  provisioner "local-exec" {
    command = <<EOF
      kubectl --kubeconfig=./kubeconfig/config-${terraform.workspace} apply -f ../03-monitoring/grafana-nodeport/
    EOF
  }


  depends_on = [
    null_resource.kube_prometheus
  ]

  triggers = {
    # cluster_instance_ids = join(",",[join(",",yandex_compute_instance.control.*.id), join(",",yandex_compute_instance.worker.*.id)])
    prometheus_deployed = null_resource.kube_prometheus.id
  }
}
