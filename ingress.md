## Step 4 - Configuring Nginx Ingress Rules for frontend Services

To `expose` frontend applications (services) to the outside world, you need to tell your `Ingress Controller` what `host` each `service` maps to. `Nginx` follows a simple pattern in which you define a set of `rules`. Each `rule` associates a `host` to a frontend `service` via a corresponding path `prefix`.

Typical ingress resource for `Nginx` looks like below (example given for the `echo` service):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-echo
  namespace: frontend
spec:
  rules:
    - host: www.abumahir.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: echo
                port:
                  number: 8080
  ingressClassName: nginx
```

Explanations for the above configuration:

- `spec.rules`: A list of host rules used to configure the Ingress. If unspecified, or no rule matches, all traffic is sent to the default frontend.
- `spec.rules.host`: Host is the fully qualified domain name of a network host (e.g.: `www.abumahir.com`).
- `spec.rules.http`: List of http selectors pointing to backend.
- `spec.rules.http.paths`: A collection of paths that map requests to frontends. In the above example the `/` path prefix is matched with the `echo` frontend `service`, running on port `8080`.

The above ingress resource tells `Nginx` to `route` each `HTTP request` that is using the `/` prefix for the `www.abumahir.com` host, to the `echo` frontend `service` running on port `8080`. In other words, every time you make a call to `http://www.abumahir.com/` the request and reply will be served by the `echo` frontend `service` running on port `8080`.

You can have multiple ingress controllers per cluster if desired, hence there's an important configuration element present which defines the ingress class name:

```yaml
ingressClassName: nginx
```

The above `ingressClassName` field is required in order to differentiate between `multiple` ingress controllers present in your `cluster`. For more information please read [What is ingressClassName field](https://kubernetes.github.io/ingress-nginx/#what-is-ingressclassname-field) from the Kubernetes-maintained `Nginx` documentation.


You can define `multiple rules` for different `hosts` and `paths` in a single `ingress` resource. To keep things organized (and for better visibility), `Starter Kit` tutorial provides two ingress manifests for each host: [echo](k8s/manifests/ingress.yaml) and [quote](k8s/manifests/quote_host.yaml).


First, `open` and `inspect` each `frontend service` ingress manifest using a text editor of your choice (preferably with `YAML` lint support). For example you can use [VS Code](https://code.visualstudio.com):

```shell
code k8s/manifests/ingress.yaml

code k8s/manifests/quote_host.yaml
```

Next, go ahead and apply each ingress resource using `kubectl`:

```shell
kubectl apply -f k8s/manifests/ingress.yaml

kubectl apply -f k8s/manifests/quote_host.yaml
```

Verify `ingress` resources `status`:

```shell
kubectl get ingress -n frontend
```

The output looks similar to (notice the `ADDRESS` column pointing to the `load balancer` resource `external IP`):

```text
NAME            CLASS   HOSTS                      ADDRESS           PORTS   AGE
ingress-echo    nginx   www.abumahir.com    143.244.204.126   80      22h
ingress-quote   nginx   app.abumahir.com   143.244.204.126   80      22h
```

Finally, test the `Nginx` setup using `curl` (or your favorite web browser) for each frontend service.

First, the `echo` service:

```shell
curl -Li http://www.abumahir.com/
```

The output looks similar to:

```text
HTTP/1.1 200 OK
Date: Thu, 04 Nov 2021 15:50:38 GMT
Content-Type: text/plain
Content-Length: 347
Connection: keep-alive

Request served by echo-5d8d65c665-569zf

HTTP/1.1 GET /

Host: www.abumahir.com
X-Real-Ip: 10.114.0.4
X-Forwarded-Port: 80
User-Agent: curl/7.77.0
X-Forwarded-Host: www.abumahir.com
X-Forwarded-Proto: http
X-Forwarded-Scheme: http
X-Scheme: http
Accept: */*
X-Request-Id: f45e2c0b8efed70b4692e1d76001286d
X-Forwarded-For: 10.114.0.4
```

Then, `quote` service:

```shell
curl -Li http://app.abumahir.com/
```

The output looks similar to:

```text
HTTP/1.1 200 OK
Date: Thu, 04 Nov 2021 15:48:20 GMT
Content-Type: application/json
Content-Length: 151
Connection: keep-alive

{
  "server": "ellipsoidal-elderberry-7kwkpxz5",
  "quote": "A late night does not make any sense.",
  "time": "2021-11-04T15:48:20.198059817Z"
}
```


If the output looks like above, then you configured `Nginx` ingress successfully.

In the next step, you will enable `Nginx` to use proper `TLS` termination. By default it comes with `self signed` certificates, for testing purpose only.

## Step 5 - Configuring Production Ready TLS Certificates for Nginx

In the default setup, `Nginx` comes with `self signed` TLS certificates. For live environments you will want to enable `Nginx` to use `production` ready `TLS` certificates. The recommended way is via [Cert-Manager](https://cert-manager.io). In the next steps, you will learn how to quickly install `cert-manager` via `Helm`, and then configure it to issue `Let's Encrypt` certificates. Certificates `renewal` happen `automatically` via `cert-manager`.

First, change directory (if not already) where you cloned the `Starter Kit` repository:

```shell
cd Kubernetes-Starter-Kit-Developers
```

Next, please add the `Jetstack` Helm repository:

```shell
helm repo add jetstack https://charts.jetstack.io
```

Next, update the `jetstack` chart repository:

```shell
helm repo update jetstack
```

Then, open and inspect the `03-setup-ingress-controller/assets/manifests/cert-manager-values-v1.8.0.yaml` file provided in the `Starter Kit` repository, using an editor of your choice (preferably with `YAML` lint support). For example, you can use [VS Code](https://code.visualstudio.com):

```shell
code 03-setup-ingress-controller/assets/manifests/cert-manager-values-v1.8.0.yaml
```

Finally, you can install the `jetstack/cert-manager` chart using Helm:

```shell
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```

Check Helm release status:

```shell
helm ls -n cert-manager
```

The output looks similar to (notice the `STATUS` column which has the `deployed` value):

```text
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
cert-manager    cert-manager    1               2021-10-20 12:13:05.124264 +0300 EEST   deployed        cert-manager-v1.8.0     v1.8.0
```

Inspect `Kubernetes` resources created by the `cert-manager` Helm release:

```shell
kubectl get all -n cert-manager
```

The output looks similar to (notice the `cert-manager` pod and `webhook` service, which should be `UP` and `RUNNING`):

```text
NAME                                           READY   STATUS    RESTARTS   AGE
pod/cert-manager-5ffd4f6c89-ckc9n              1/1     Running   0          10m
pod/cert-manager-cainjector-748dc889c5-l4dbv   1/1     Running   0          10m
pod/cert-manager-webhook-5b679f47d6-4xptd      1/1     Running   0          10m

NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/cert-manager-webhook   ClusterIP   10.245.227.199   <none>        443/TCP   10m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cert-manager              1/1     1            1           10m
deployment.apps/cert-manager-cainjector   1/1     1            1           10m
deployment.apps/cert-manager-webhook      1/1     1            1           10m

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/cert-manager-5ffd4f6c89              1         1         1       10m
replicaset.apps/cert-manager-cainjector-748dc889c5   1         1         1       10m
replicaset.apps/cert-manager-webhook-5b679f47d6      1         1         1       10m
```

Inspect the available `CRDs`:

```shell
kubectl get crd -l app.kubernetes.io/name=cert-manager
```

The output looks similar to:

```text
NAME                                  CREATED AT
certificaterequests.cert-manager.io   2022-01-07T14:17:55Z
certificates.cert-manager.io          2022-01-07T14:17:55Z
challenges.acme.cert-manager.io       2022-01-07T14:17:55Z
clusterissuers.cert-manager.io        2022-01-07T14:17:55Z
issuers.cert-manager.io               2022-01-07T14:17:55Z
orders.acme.cert-manager.io           2022-01-07T14:17:55Z
```

Next, you will configure a certificate `Issuer` resource for `cert-manager`, which is responsible with fetching the `TLS` certificate for `Nginx` to use. The certificate issuer is using the `HTTP-01` challenge provider to accomplish the task.

Typical `Issuer` manifest looks like below (explanations for each relevant field is provided inline):

```yaml
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-nginx
  namespace: frontend
spec:
  # ACME issuer configuration
  # `email` - the email address to be associated with the ACME account (make sure it's a valid one)
  # `server` - the URL used to access the ACME server’s directory endpoint
  # `privateKeySecretRef` - Kubernetes Secret to store the automatically generated ACME account private key
  acme:
    email: <YOUR_VALID_EMAIL_ADDRESS_HERE>
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-nginx-private-key
    solvers:
      # Use the HTTP-01 challenge provider
      - http01:
          ingress:
            class: nginx
```

You can create the above `Issuer` resource using the template provided in the `Starter Kit` repository (make sure you change directory where the `Starter Kit` repository was cloned on your local machine first):

```shell
kubectl apply -f k8s/manifests/cert-manager-issuer.yaml
```

Check that the `Issuer` resource was created and that `no error` is reported:

```shell
kubectl get issuer -n frontend
```

The output looks similar to:

```text
NAME                READY   AGE
letsencrypt-nginx   True    16m
```

Next, you need to configure each `Nginx` ingress resource to use `TLS`. Typical manifest looks like below:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-echo
  namespace: frontend
  annotations:
    cert-manager.io/issuer: letsencrypt-nginx
spec:
  tls:
  - hosts:
    - www.abumahir.com
    secretName: letsencrypt-nginx
  rules:
    - host: www.abumahir.com
...
```

Explanation for the above configuration:

- `cert-manager.io/issuer`: Annotation that takes advantage of cert-manager [ingress-shim](https://cert-manager.io/docs/usage/ingress) to create the certificate resource on your behalf. Notice that it points to the `letsencrypt-nginx` Issuer resource created earlier.
- `spec.tls.hosts`: List of hosts included in the TLS certificate.
- `spec.tls.secretName`: Name of the secret used to terminate TLS traffic on port 443.

Now, please open `ingress.yaml` and `quote_host.yaml` using a text editor of your choice (preferably with `YAML` lint support). Then, uncomment `annotations` and `spec.tls`, as explained above. For example, you can use [VS Code](https://code.visualstudio.com):

```shell
code k8s/manifests/ingress.yaml

code k8s/manifests/quote_host.yaml
```

Save the `ingress.yaml` and `quote_host.yaml` files, and apply changes using `kubectl`:

```shell
kubectl apply -f k8s/manifests/ingress.yaml

kubectl apply -f k8s/manifests/quote_host.yaml
```

After a few moments, inspect `ingress` object `state`:

```shell
kubectl get ingress -n frontend
```

The output looks similar to (notice that the `www.abumahir.com` and `app.abumahir.com` hosts now have proper `TLS` termination, denoted by the `443` port number presence in the `PORTS` column):

```text
ingress-echo    nginx   www.abumahir.com    157.230.66.23   80, 443   11m
ingress-quote   nginx   app.abumahir.com   157.230.66.23   80, 443   11m
```

Check that the certificate resource was created as well:

```shell
kubectl get certificates -n frontend
```

The output looks similar to (notice the `READY` column status which should be `True`):

```text
letsencrypt-nginx-echo    True    letsencrypt-nginx-echo    3m50s
letsencrypt-nginx-quote   True    letsencrypt-nginx-quote   38s
```

Finally, test the `echo` and `quote` services via `curl` (notice that you receive a `redirect` to use `HTTPS` instead):

```shell
curl -Li http://www.abumahir.com/
```

The output looks similar to:

```text
HTTP/1.1 308 Permanent Redirect
Date: Thu, 04 Nov 2021 16:00:09 GMT
Content-Type: text/html
Content-Length: 164
Connection: keep-alive
Location: https://www.abumahir.com

HTTP/2 200 
date: Thu, 04 Nov 2021 16:00:10 GMT
content-type: text/plain
content-length: 351
strict-transport-security: max-age=15724800; includeSubDomains

Request served by echo-5d8d65c665-569zf

HTTP/1.1 GET /

Host: www.abumahir.com
X-Forwarded-Port: 443
X-Request-Id: c5b0593a12dcda6c10698edfbd349e3b
X-Real-Ip: 10.114.0.4
X-Forwarded-For: 10.114.0.4
X-Forwarded-Host: www.abumahir.com
X-Forwarded-Proto: https
X-Forwarded-Scheme: https
X-Scheme: https
User-Agent: curl/7.77.0
Accept: */*
```

```shell
curl -Li http://app.abumahir.com/
```

The output looks similar to:

```text
HTTP/1.1 308 Permanent Redirect
Date: Tue, 07 Jun 2022 06:10:26 GMT
Content-Type: text/html
Content-Length: 164
Connection: keep-alive
Location: https://app.abumahir.com

HTTP/2 200 
date: Tue, 07 Jun 2022 06:10:27 GMT
content-type: application/json
content-length: 159
strict-transport-security: max-age=15724800; includeSubDomains

{
    "server": "lumbering-mulberry-30bd7l5q",
    "quote": "A principal idea is omnipresent, much like candy.",
    "time": "2022-06-07T06:10:27.046014854Z"
}
```

You can also test the service using a web browser of your choice. Notice that you're redirected to use `HTTPS` instead, and that the `certificate` is a valid one, issued by [Let's Encrypt](https://letsencrypt.org):

![Echo Host Let's Encrypt Certificate](assets/images/nginx_echo_tls_cert.png)

For more information about `cert-manager` ingress support and features, please visit the official [ingress-shim](https://cert-manager.io/docs/usage/ingress/) documentation page.

In the next step, you will learn how to use the `DigitalOcean Proxy Protocol` with `Nginx` Ingress Controller.

## Step 6 - Enabling Proxy Protocol

A `L4` load balancer replaces the original `client IP` with its `own IP` address. This is a problem, as you will lose the `client IP` visibility in the application, so you need to enable `proxy protocol`. Proxy protocol enables a `L4 Load Balancer` to communicate the `original` client `IP`. For this to work, you need to configure both `DigitalOcean Load Balancer` and `Nginx`.

After deploying the [frontend Services](#step-3---creating-the-nginx-frontend-services), you need to configure the nginx Kubernetes `Service` to use the `proxy protocol` and `tls-passthrough`. This annotations are made available by the `DigitalOcean Cloud Controller`:

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol`
- `service.beta.kubernetes.io/do-loadbalancer-tls-passthrough`

First, you need to edit the `Helm` values file provided in the `Starter Kit` repository using an editor of your choice (preferably with `YAML` lint support). For example, you can use [VS Code](https://visualstudio.microsoft.com):

```shell
code 03-setup-ingress-controller/assets/manifests/nginx-values-v4.1.3.yaml
```

Then, uncomment the `annotations` settings from the `service` section, like in the below example:

```yaml
service:
  type: LoadBalancer
  annotations:
    # Enable proxy protocol
    service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
    # Specify whether the DigitalOcean Load Balancer should pass encrypted data to frontend droplets
    service.beta.kubernetes.io/do-loadbalancer-tls-passthrough: "true"
```

**Note:**

You must **NOT** create a load balancer with `Proxy` support by using the `DigitalOcean` web console, as any setting done outside `DOKS` is automatically `overridden` by DOKS `reconciliation`.

Then, uncomment the `config` section as seen below to allow Nginx to receive client connection information:

```yaml
config:
  use-proxy-protocol: "true"
```

Then, save the values file and apply changes using `Helm`:

```shell
NGINX_CHART_VERSION="4.1.3"

helm upgrade ingress-nginx ingress-nginx/ingress-nginx --version "$NGINX_CHART_VERSION" \
  --namespace ingress-nginx \
  -f "03-setup-ingress-controller/assets/manifests/nginx-values-v${NGINX_CHART_VERSION}.yaml"
```

Finally, test the `echo` service via `curl` (notice that your Public IP will be present in `X-Forwarded-For` and `X-Real-Ip` headers):

```shell
curl -Li https://www.abumahir.com/
```

```shell
HTTP/2 200
date: Thu, 23 Dec 2021 10:26:02 GMT
content-type: text/plain
content-length: 356
strict-transport-security: max-age=15724800; includeSubDomains

Request served by echo-5d8d65c665-fpbwx

HTTP/1.1 GET /echo/

Host: www.abumahir.com
X-Real-Ip: 79.119.116.72
X-Forwarded-For: 79.119.116.72
X-Forwarded-Host: www.abumahir.com
X-Forwarded-Proto: https
User-Agent: curl/7.77.0
X-Request-Id: b167a24f6ac241442642c3abf24d7517
X-Forwarded-Port: 443
X-Forwarded-Scheme: https
X-Scheme: https
Accept: */*
```
