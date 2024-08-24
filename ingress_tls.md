# Set Up a TLS Certificate ingress
## Option A: Use a TLS certificate from a Certificate Authority (CA):
- Purchase or obtain a certificate from a trusted CA.
- Create a Kubernetes secret to store the TLS certificate and private key
```
kubectl create secret tls your-tls-secret --cert=path/to/cert.crt --key=path/to/private.key
```

## Option B: Use a free TLS certificate from Let's Encrypt:
- Use a tool like Cert-Manager to automatically request and manage TLS certificates from Let's Encrypt.

1. Install Cert-Manager (if not already installed)
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

2. Create an Issuer or ClusterIssuer
The Issuer is a namespace-scoped resource, while the ClusterIssuer is cluster-wide. You'll choose based on your needs:
- Issuer: Used for managing certificates within a single namespace.
- ClusterIssuer: Used for managing certificates across multiple namespaces.

```
nano clusterissuer.yaml
```

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx


```
- `server:` URL for the ACME server. For production, use https://acme-v02.api.letsencrypt.org/directory.
- `email:` Your email address, used by Let's Encrypt for urgent renewal and security notices.
- `privateKeySecretRef.name:` The name of the secret where your private key will be stored.
- `solvers:` Defines how the ACME challenge will be solved. Here, http01 is used via an Ingress controller.

Apply the above YAML file:
```
kubectl apply -f clusterissuer.yaml
```

3. Create a Certificate Resource
```
nano certificate.yaml
```

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: abumahir-com-tls
  namespace: default
spec:
  secretName: abumahir-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: abumahir.com
  dnsNames:
  - abumahir.com


```
`secretName:` The name of the Kubernetes secret where the certificate and private key will be stored.
`issuerRef:` References the Issuer or ClusterIssuer to use.
`commonName:` The primary domain for the certificate.
`dnsNames:` Additional domains for which the certificate should be valid.
`acme.config:` Specifies how Cert-Manager should solve the ACME challenge.

```
kubectl apply -f certificate.yaml
```

5. Verify the Certificate
```
kubectl describe certificate your-certificate -n your-namespace
```

6. Use the Certificate in Your Ingress
Finally, update your Ingress resource to use the generated certificate by referencing the secretName specified in the Certificate resource.
Example:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: react-app-github-actions
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - abumahir.com
    secretName: abumahir-com-tls  # Must match the secret name in the Certificate resource
  rules:
  - host: abumahir.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: react-app-github-actions
            port:
              number: 80
      - path: /grafana
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
      - path: /prometheus
        pathType: Prefix
        backend:
          service:
            name: prometheus-server
            port:
              number: 9090
      - path: /argocd
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 8080


```
5. Point DNS to Ingress Controller
Ensure that your domain (abumahir.com) is correctly pointed to your Kubernetes cluster’s Ingress controller. You can do this by setting an A record in your external DNS provider that points to the IP address of your Ingress controller.

6. Verify the Deployment
Once you've applied the updated Ingress resource, Cert-Manager should automatically obtain the TLS certificate for your domain. You can verify the deployment by checking if your application is accessible over HTTPS.

Apply the Configuration:
Finally, apply the configuration with:
```
kubectl apply -f your-ingress-file.yaml
kubectl apply -f your-certificate-file.yaml

```
