## Install Kubectl
```
sudo snap install kubectl --classic
```


## Install doctl (digitalocean cmd)
```
snap install doctl
```
## Authenticate with Digitalocean Token
```
doctl auth init
```

```
export KUBECONFIG=./k8s-cluster-kubeconfig.yaml
```


## create k8s cluster
create folder called manifest then cd into manifest
create deployement.yaml

```
  # This is a sample deployment manifest file for a simple web application.
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: go-web-app
    labels:
      app: go-web-app
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: go-web-app
    template:
      metadata:
        labels:
          app: go-web-app
      spec:
        containers:
        - name: go-web-app
          image: <docker-user-name>/go-web-app:latest
        ports:
        - containerPort: 8080
```

### create service.yaml
```
# This is a sample deployment manifest file for a simple web application.
# Service for the application
apiVersion: v1
kind: Service
metadata:
  name: go-web-app
  labels:
    app: go-web-app
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: go-web-app
  type: ClusterIP

```

### create ingress.yaml
# This is a sample deployment manifest file for a simple web application.
# Ingress resource for the application
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-web-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: go-web-app.local
    http:
      paths: 
      - path: /
        pathType: Prefix
        backend:
          service:
            name: go-web-app
            port:
              number: 80
```