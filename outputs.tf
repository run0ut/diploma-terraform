output "control_nodes" {
  value = [
    for n in yandex_compute_instance.control :
    "name=${n.name}, public=${n.network_interface.0.nat_ip_address}, private=${n.network_interface.0.ip_address}"
  ]
  description = "IP инстансов control нод"
}

output "worker_nodes" {
  value = [
    for n in yandex_compute_instance.worker :
    "name=${n.name}, public=${n.network_interface.0.nat_ip_address}, private=${n.network_interface.0.ip_address}"
  ]
  description = "IP инстансов control нод"
}

output "links" {
  value       = <<EOF
       App: http://${yandex_compute_instance.control.0.network_interface.0.nat_ip_address}:30080
   Jenkins: http://${yandex_compute_instance.control.0.network_interface.0.nat_ip_address}:30808
  Atlantis: http://${yandex_compute_instance.control.0.network_interface.0.nat_ip_address}:30141
   Grafana: http://${yandex_compute_instance.control.0.network_interface.0.nat_ip_address}:30300
  EOF
  description = "IP инстансов control нод"
}