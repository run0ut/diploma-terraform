apiVersion: apps/v1
kind: Deployment
metadata:
  name: diploma-test-app
  labels:
    app.kubernetes.io/name: diploma-test-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: diploma-test-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: diploma-test-app
    spec:
      containers:
      - name: diploma-test-app
        image: ${login}/diploma-test-app:latest
        ports:
        - containerPort: 80