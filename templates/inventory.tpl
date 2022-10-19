[all]
${connection_strings_master}
${connection_strings_node}

[kube_control_plane]
${list_master}

[kube_node]
${list_node}

[etcd]
${list_master}

[k8s_cluster:children]
kube_node
kube_control_plane