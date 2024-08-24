# How to Configure Ingress using Nginx

## Introduction

In this tutorial, you will learn how to use the Kubernetes-maintained [Nginx](https://kubernetes.github.io/ingress-nginx) Ingress Controller. Then, you're going to discover how to have `TLS` certificates automatically deployed and configured for your hosts (thus enabling `TLS` termination), and `route` traffic to your `frontend` applications.

Why use Kubernetes-maintained `Nginx` ?

- Open source (driven by the Kubernetes community).
- Lot of support from the Kubernetes community.
- Flexible way of routing traffic to your services inside the cluster.
- `TLS` certificates support and auto renewal via [Cert-Manager](https://cert-manager.io).

As with every Ingress Controller, `Nginx` allows you to define ingress objects. Each ingress object contains a set of rules that define how to route external traffic (HTTP requests) to your frontend services. For example, you can have multiple hosts defined under a single domain, and then let `Nginx` take care of routing traffic to the correct host.

`Ingress Controller` sits at the `edge` of your `VPC`, and acts as the `entry point` for your `network`. It knows how to handle `HTTP` requests only, thus it operates at `layer 7` of the `OSI` model. When `Nginx` is deployed to your `DOKS` cluster, a `load balancer` is created as well, through which it receives the outside traffic. Then, you will have a `domain` set up with `A` type records (hosts), which in turn point to your load balancer `external IP`. So, data flow goes like this: `User Request -> Host.DOMAIN -> Load Balancer -> Ingress Controller (NGINX) -> frontend Applications (Services)`.

After finishing this tutorial, you will be able to:

- Create and manage `Nginx` Helm deployments.
- Create and configure basic `HTTP` rules for `Nginx`, to `route` requests to your `frontend` applications.
- Automatically configure `TLS` certificates for your `hosts`, thus having `TLS` termination.


## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Step 1 - Installing the Nginx Ingress Controller](#step-1---installing-the-nginx-ingress-controller)
- [Step 2 - Configuring DNS for Nginx Ingress Controller](#step-2---configuring-dns-for-nginx-ingress-controller)
- [Step 3 - Creating the Nginx frontend Services](#step-3---creating-the-nginx-frontend-services)
- [Step 4 - Configuring Nginx Ingress Rules for frontend Services](#step-4---configuring-nginx-ingress-rules-for-frontend-services)
- [Step 5 - Configuring Production Ready TLS Certificates for Nginx](#step-5---configuring-production-ready-tls-certificates-for-nginx)
- [Step 6 - Enabling Proxy Protocol](#step-6---enabling-proxy-protocol)
- [How To Guides](#how-to-guides)
  - [Setting up Ingress to use Wildcard Certificates](guides/wildcard_certificates.md)
  - [Ingress Controller LoadBalancer Migration](guides/ingress_loadbalancer_migration.md)
  - [Performance Considerations for Nginx](guides/nginx_performance_considerations.md)
- [Conclusion](#conclusion)

# How to Configure Ingress using Nginx

### Prerequisites
To complete this tutorial, you will need:
1. A [Git](https://git-scm.com/downloads) client, to clone the `Starter Kit` repository.
2. [Helm](https://www.helm.sh), for managing `Nginx` releases and upgrades.
3. [Doctl](https://github.com/digitalocean/doctl/releases), for `DigitalOcean` API interaction.
4. [Kubectl](https://kubernetes.io/docs/tasks/tools), for `Kubernetes` interaction.
5. [Curl](https://curl.se/download.html), for testing the examples (frontend applications).

Please make sure that `doctl` and `kubectl` context is configured to point to your `Kubernetes` cluster - refer to [Step 2 - Authenticating to DigitalOcean API](../01-setup-DOKS/README.md#step-2---authenticating-to-digitalocean-api) and [Step 3 - Creating the DOKS Cluster](../01-setup-DOKS/README.md#step-3---creating-the-doks-cluster) from the `DOKS` setup tutorial.

## Step 1 - Installing the Nginx Ingress Controller
1. First, clone the Starter Kit repository and change directory to your local copy.
```
https://github.com/Boubamahir2/react_app_github_actions.git
```

2. Next, add the Helm repo, and list the available charts:
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update ingress-nginx

helm search repo ingress-nginx
```

The output looks similar to the following:
```
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
ingress-nginx/ingress-nginx     4.1.3           1.2.1           Ingress controller for Kubernetes using NGINX
```

## Note:

The chart of interest is ingress-nginx/ingress-nginx, which will install Kubernetes-maintained Nginx on the cluster. Please visit the kubernetes-nginx page, for more details about this chart.

4. Finally, install the Nginx Ingress Controller using Helm
## helm install ingress controller
```
kubectl create namespace ingress-nginx
```

Then, open and inspect the /path/values.yaml
```
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f /k8s/manifests/values.yaml
```

## helm install ingress controller
```
helm upgrade ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f /path/values.yaml

```
You have installed the nginx Ingress Controller. It will now automatically create a Load Balancer on your behalf.

5. Use this command to get the IP address:
```
watch kubectl -n ingress-nginx get svc
```
### You can verify Nginx deployment status via:
```
kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide
```

- You can verify Nginx deployment status via:
```
helm ls -n ingress-nginx
```
```
helm list
```
```
helm upgrade react-app-chart-1723671969 ./react-app-chart
```
- The output looks similar to (notice that the STATUS column value is deployed):
```
NAME            NAMESPACE       REVISION   UPDATED                                 STATUS     CHART                   APP VERSION
ingress-nginx   ingress-nginx   1          2021-11-02 10:12:44.799499 +0200 EET    deployed   ingress-nginx-4.1.3     1.2.1
```

- Next check Kubernetes resources created for the ingress-nginx namespace
```
kubectl get all -n ingress-nginx
```
- The output looks similar to:
```
NAME                                            READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-5c8d66c76d-m4gh2   1/1     Running   0          56m

NAME                                         TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.245.27.99   143.244.204.126   80:32462/TCP,443:31385/TCP   56m
service/ingress-nginx-controller-admission   ClusterIP      10.245.44.60   <none>            443/TCP                      56m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           56m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-5c8d66c76d   1         1         1       56m
```


- Check Ingress Controller Logs
```
kubectl get pods -n ingress-nginx
```

- Check Application Logs
```
kubectl logs -n ingress-nginx <nginx-ingress-controller-pod-name>
```

- Check Ingress Configuration
```
kubectl describe ingress react-app-github-actions
```

- list all load balancer resources from your DigitalOcean account, and print the IP,  ID, Name and Status:
```
doctl compute load-balancer list --format IP,ID,Name,Status
```

## Step 2 - Configuring DNS for Nginx Ingress Controller
In this step, you will configure DNS within your DigitalOcean account, using a domain that you own. Then, you will create the domain A records for each host: app and www. Please bear in mind that DigitalOcean is not a domain name registrar. You need to buy a domain name first from Google, GoDaddy, etc.
- First, please issue the below command to create a new domain (example.com, in this example):
```
doctl compute domain create example.com
```

- The output looks similar to the following:
```
Domain                TTL
abumahir.com    0
```

## Note:

### YOU NEED TO ENSURE THAT YOUR DOMAIN REGISTRAR IS CONFIGURED TO POINT TO DIGITALOCEAN NAME SERVERS. More information on how to do that is available here.
Next, you will add required A records for the hosts you created earlier. First, you need to identify the load balancer external IP created by the nginx deployment:
```
kubectl get svc -n ingress-nginx
```

- The output looks similar
```
NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.245.27.99   143.244.204.126   80:32462/TCP,443:31385/TCP   96m
ingress-nginx-controller-admission   ClusterIP      10.245.44.60   <none>            443/TCP                      96m
```

- Then, add the records (please replace the <> placeholders accordingly). You can change the TTL value as per your requirement:
```
doctl compute domain records create abumahir.com --record-type "A" --record-name "app" --record-data "<YOUR_LB_IP_ADDRESS>" --record-ttl "30"

doctl compute domain records create abumahir.com --record-type "A" --record-name "www" --record-data "<YOUR_LB_IP_ADDRESS>" --record-ttl "30"
```

### Hint:
- If you have only one load balancer in your account, then please use the following snippet:
```
LOAD_BALANCER_IP=$(doctl compute load-balancer list --format IP --no-header)

doctl compute domain records create abumahir.com --record-type "A" --record-name "app" --record-data "$LOAD_BALANCER_IP" --record-ttl "30"

doctl compute domain records create abumahir.com --record-type "A" --record-name "www" --record-data "$LOAD_BALANCER_IP" --record-ttl "30"
```

### Observation and results:
```
doctl compute domain records list abumahir.com
```
- The output looks similar to the following:
ID           Type    Name     Data                    Priority    Port    TTL     Weight
164171755    SOA     @        1800                    0           0       1800    0
164171756    NS      @        ns1.digitalocean.com    0           0       1800    0
164171757    NS      @        ns2.digitalocean.com    0           0       1800    0
164171758    NS      @        ns3.digitalocean.com    0           0       1800    0
164171801    A       app      143.244.204.126         0           0       3600    0
164171809    A       www      143.244.204.126         0           0       3600    0

At this point the network traffic will reach the Nginx enabled cluster, but you need to configure the frontend services paths for each of the hosts. All DNS records have one thing in common: TTL or time to live. It determines how long a record can remain cached before it expires. Loading data from a local cache is faster, but visitors won’t see DNS changes until their local cache expires and gets updated after a new DNS lookup. As a result, higher TTL values give visitors faster performance, and lower TTL values ensure that DNS changes are picked up quickly. All DNS records require a minimum TTL value of 30 seconds.


## Step 3 - Creating the Nginx frontend Services
In this step, you will deploy two example `frontend` services (applications), named `app` and `www` to test the `Nginx` ingress setup.

You can have multiple `TLS` enabled `hosts` on the same cluster. On the other hand, you can have multiple `deployments` and `services` as well. So for each `frontend` application, a corresponding Kubernetes `Deployment` and `Service` has to be created.

First, you define a new `namespace` for the `www` and `app` frontend applications. This is good practice in general, because you don't want to pollute the `Nginx` namespace (or any other), with application specific stuff.

Steps to follow:

Steps to follow:

1. First, change directory (if not already) where the `Starter Kit` repository was cloned:

    ```shell
    cd Kubernetes-Starter-Kit-Developers
    ```

2. Next, create the `frontend` namespace:

    ```shell
    kubectl create ns frontend
    ```

3. Then, create the [app](k8s/manifests/deployement.yaml) and [www](k8s/manifests/echo_deployment.yaml) deployments:

    ```shell
    kubectl apply -f k8s/manifests/deployement.yaml

    kubectl apply -f k8s/manifests/echo_deployment.yaml
    ```

4. Finally, create the corresponding `services`:

    ```shell
    kubectl apply -f k8s/manifests/service.yaml

    kubectl apply -f k8s/manifests/echo_service.yaml
    ```

**Observation and results:**
Inspect the `deployments` and `services` you just created:

```shell
kubectl get deployments -n frontend
```
The output looks similar to the following
```text
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
app    1/1     1            1           2m22s
www   1/1     1            1           2m23s
```

```shell
kubectl get svc -n frontend
```

The output looks similar to the following

```text
NAME    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
app    ClusterIP   10.245.115.112   <none>        80/TCP    3m3s
echo   ClusterIP   10.245.226.141   <none>        80/TCP    3m3s
```