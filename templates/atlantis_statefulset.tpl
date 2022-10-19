apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: atlantis
spec:
  serviceName: atlantis
  replicas: 1
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  selector:
    matchLabels:
      app: atlantis
  template:
    metadata:
      labels:
        app: atlantis
    spec:

      securityContext:
        fsGroup: 1000 # Atlantis group (1000) read/write access to volumes.

      initContainers:
      - name: volume-mount-hack
        image: busybox
        command:
          - sh
          - "-c"
          - |
            chown -R 100:1000 /atlantis
            cp -r /home/atlantis_temp/. /home/atlantis/
            chown -R 100:1000 /home/atlantis/
            chmod 600 /home/atlantis/.ssh/*
        volumeMounts:
        - name: atlantis-data
          mountPath: /atlantis
        - name: atlantis-home
          mountPath: /home/atlantis
        - name: ssh
          mountPath: /home/atlantis_temp/.ssh/id_rsa
          subPath: id_rsa
        - name: ssh-pub
          mountPath: /home/atlantis_temp/.ssh/id_rsa.pub
          subPath: id_rsa.pub
        - name: terraformrc
          mountPath: /home/atlantis_temp/.terraformrc
          subPath: .terraformrc
        - name: auto-tfvars
          mountPath: /home/atlantis_temp/.auto.tfvars
          subPath: .auto.tfvars
        - name: key-json
          mountPath: /home/atlantis_temp/key.json
          subPath: key.json
        - name: server-config
          mountPath: /home/atlantis_temp/server.yaml
          subPath: server.yaml

      containers:
      - name: atlantis
        image: ghcr.io/runatlantis/atlantis:v0.20.1
        # command: ["sleep", "360000"]
        command: ["docker-entrypoint.sh"] 
        args: 
          - "server"
          - "--atlantis-url=http://${atlantis_ip}:30141/"
          - "--var-file-allowlist=/home/atlantis"
          - "--tf-download-url=https://terraform-mirror.yandexcloud.net/"
          - "--repo-config=/home/atlantis/server.yaml"
          - "--enable-diff-markdown-format"
        env:
        - name: ATLANTIS_REPO_ALLOWLIST
          value: github.com/${login}/diploma-terraform # 2. Replace this with your own repo allowlist.
        ### GitHub Config ###
        - name: ATLANTIS_GH_USER
          value: ${login} # 3. If you're using GitHub replace <YOUR_GITHUB_USER> with the username of your Atlantis GitHub user without the `@`.
        - name: ATLANTIS_GH_TOKEN
          valueFrom:
            secretKeyRef:
              name: atlantis-vcs
              key: token
        - name: ATLANTIS_GH_WEBHOOK_SECRET
          valueFrom:
            secretKeyRef:
              name: atlantis-vcs
              key: webhook-secret
        ### End GitHub Config ###
        - name: ATLANTIS_DATA_DIR
          value: /atlantis
        - name: ATLANTIS_PORT
          value: "4141" # Kubernetes sets an ATLANTIS_PORT variable so we need to override.

        volumeMounts:
        - name: atlantis-data
          mountPath: /atlantis
        - name: atlantis-home
          mountPath: /home/atlantis

        ports:
        - name: atlantis
          containerPort: 4141

        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 256Mi
            cpu: 100m

      volumes:
      - name: atlantis-home
        emptyDir: { }
      - name: atlantis-data
        persistentVolumeClaim:
          claimName: atlantis-data
      - name: ssh
        configMap:
          name: atlantis-files
          items: 
          - key: ssh
            path: id_rsa
      - name: ssh-pub
        configMap:
          name: atlantis-files
          items:
          - key: ssh-pub
            path: id_rsa.pub
      - name: terraformrc
        configMap:
          name: atlantis-files
          items:
          - key: terraformrc
            path: .terraformrc
      - name: auto-tfvars
        configMap:
          name: atlantis-files
          items:
          - key: auto-tfvars
            path: .auto.tfvars
      - name: key-json
        configMap:
          name: atlantis-files
          items:
          - key: key-json
            path: key.json
      - name: server-config
        configMap:
          name: atlantis-files
          items:
          - key: server-config
            path: server.yaml