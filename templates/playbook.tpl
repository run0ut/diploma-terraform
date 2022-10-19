---
- name: Get kuber credentials
  hosts: diploma-control-${workspace}-0
  become: yes
  gather_facts: yes
  tasks:
    - name: Save host to var
      set_fact:
        kube_control_node: "{{ ansible_host }}"
    - name: Print fact
      debug:
        var: kube_control_node

    - name: Duplicate folder kube
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /etc/kubernetes/admin_export.conf
        remote_src: yes
        mode: 0755

    - name: Set Kube IP in config
      replace:
        path: /etc/kubernetes/admin_export.conf
        regexp: "server: https://[0-9.]*:"
        replace: "server: https://{{ kube_control_node }}:"
    - name: Fetch kube config
      synchronize:
        src: /etc/kubernetes/admin_export.conf
        dest: ../kubeconfig/config-${workspace}
        delete: yes
        recursive: yes
        owner: no
        group: no
        mode: pull