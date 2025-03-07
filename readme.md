# react_app_github_actions

# DevOpsify the go web application

The main goal of this project is to implement DevOps practices in the Go web application. The project is a simple website written in Golang. It uses the `net/http` package to serve HTTP requests.

DevOps practices include the following:

- Creating Dockerfile (Multi-stage build)
- Containerization
- Continuous Integration (CI)
- Continuous Deployment (CD)

## Summary Diagram
![image](https://github.com/user-attachments/assets/45f4ef12-c5b5-4247-9d43-356b5dfb671b)


## Creating Dockerfile (Multi-stage build)
The Dockerfile is used to build a Docker image. The Docker image contains the Go web application and its dependencies. The Docker image is then used to create a Docker container.

We will use a Multi-stage build to create the Docker image. The Multi-stage build is a feature of Docker that allows you to use multiple build stages in a single Dockerfile. This will reduce the size of the final Docker image and also secure the image by removing unnecessary files and packages.

## Containerization
Containerization is the process of packaging an application and its dependencies into a container. The container is then run on a container platform such as Docker. Containerization allows you to run the application in a consistent environment, regardless of the underlying infrastructure.

We will use Docker to containerize the Go web application. Docker is a container platform that allows you to build, ship, and run containers.

Commands to build the Docker container:

```bash
docker build -t <your-docker-username>/go-web-app .
```

Command to run the Docker container:

```bash
docker run -p 3000:3000 <your-docker-username>/go-web-app
```

Command to push the Docker container to Docker Hub:

```bash
docker push <your-docker-username>/go-web-app
```

### create k8s cluster
- create folder called manifest then cd into manifest
- create deployement.yaml
```bash
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

- create service.yaml
```bash
# This is a sample service manifest file for a simple web application.
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

- create ingress.yaml
```bash
# This is a sample ingress manifest file for a simple web application.
# Ingress resource for the application
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


### install helm From Script
```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

### install helm From Apt (Debian/Ubuntu)
```
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Create helm app 
- create helm folder in the project directory
- cd helm
- helm create <your-app-chart>
- cd your-app-chart
- rm -rf charts
- cd templates and delete all the files
- rm -rf *
- cp ../../../k8s/manifests/* . copy all the manifests file from k8s


 ### paste the following code in Values.yaml in the helm app
```
# Default values for go-web-app-chart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: boubamahir/react-app-github_actions
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "10016307834"

ingress:
  enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
```

### create ingress-controller

1. Run the kubectl command to create a namespace:
```
kubectl create namespace ingress-nginx
```
2. Run the command to add the helm repository for the nginx Controller:
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```
3. Run the command to update the helm repository data:
```
helm repo update
```
4. Run the command to install the Controller: in helm app
## helm install ingress controller
```
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f /path/values.yaml
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
helm ls -n ingress-nginx
```
```
Check Ingress Controller Logs
```
kubectl get pods -n ingress-nginx
```
- Check Application Logs
```
kubectl logs -n ingress-nginx <nginx-ingress-controller-pod-name>
```
```
kubectl get all -n ingress-nginx
```

- Check Ingress Configuration
```
kubectl describe ingress react-app-github-actions
```


### Accessing the Applications
1. Local Access via hosts File
```
sudo nano /etc/hosts
```

```
<Ingress-Controller-External-IP>  react-app-github-actions.locals
```
```
kubectl get service -n ingress-nginx

```

2. Ensure Ingress Controller is Running
```
kubectl get pods -n ingress-nginx
```
### Common Troubleshooting
```
kubectl logs -n ingress-nginx <nginx-ingress-controller-pod-name>

```
```
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

```



## Continuous Integration (CI)
Continuous Integration (CI) is the practice of automating the integration of code changes into a shared repository. CI helps to catch bugs early in the development process and ensures that the code is always in a deployable state.

We will use GitHub Actions to implement CI for the Go web application. GitHub Actions is a feature of GitHub that allows you to automate workflows, such as building, testing, and deploying code.

The GitHub Actions workflow will run the following steps:
- Checkout the code from the repository
- Build the Docker image
- Run the Docker container
- Run tests

### steps in setting github actions
- create a folder .github/workfows
- create a file ci.yaml
- go to github , then settings 
- got actions , then got secrets and variables 
- create github TOKEN for secret.TOKEN
- create DOCKERHUB_USERNAME and DOCKERHUB_TOKEN variables
- got to docker hub , then Account settings-> click personal access token and generate new token, copy and paste it into DOCKERHUB_TOKEN field  
- you can visit github market place for pipeline syntanx

## paste the following code to your ci.yaml file in .github/workfows
```
name: React CI/CD

on:
  push:
    branches:
      - main
    paths-ignore:
      - 'helm/**'
      - 'k8s/**'
      - 'README.md'

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30 
    strategy:
      matrix:
        node-version: [16.x, 18.x]

    steps:
      - uses: actions/checkout@v3  # Optimized checkout action version
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }} # Modern, well-supported Node.js version
      #  caching step just before the npm install
      - name: Cache Node.js modules
        uses: actions/cache@v3
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: Install dependencies
        run: npm install

      - name: Run ESLint for code analysis
        run: npx eslint . 
        #npx eslint . --fix 
        #Automatically fixes issues like missing semicolons, spacing, and formatting that can be corrected automatically based on your ESLint configuration.


      - name: Build React project
        run: npm run build  # Assuming you have a build script in package.json
        # Or use Create React App's built-in build command:
        # run: npm run build


  push:
    runs-on: ubuntu-latest

    needs: build

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Login to DockerHub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and Push action
      uses: docker/build-push-action@v6
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/react-app-github-actions:${{github.run_id}}

  update-newtag-in-helm-chart:
    runs-on: ubuntu-latest

    needs: push

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        token: ${{ secrets.TOKEN }}

    - name: Update tag in Helm chart
      run: |
        sed -i 's/tag: .*/tag: "${{github.run_id}}"/' helm/react-app-chart/values.yaml

    - name: Commit and push changes
      run: |
        git config --global user.email "amamahir1@gmail.com"
        git config --global user.name "Boubamahir2"
        git add helm/react-app-chart/values.yaml
        git commit -m "Update tag in Helm chart"
        git push


```



## Breakdown of the React CI/CD Workflow:
This workflow defines a multi-stage pipeline for building, testing, and deploying a React application. Here's a breakdown of each section:

1. Name:
`name: React CI/CD:` This describes the overall purpose of the workflow.

2. Trigger (on):

`on: push:` The workflow runs whenever there's a push to the repository.
`branches: main:` It specifically runs for pushes to the `main` branch.
`paths-ignore:` This excludes specific files and folders from triggering the workflow, such as Helm chart files, Kubernetes configurations, and the README file. This ensures the workflow focuses on code changes relevant to the React application.
3. Jobs:

### build: This job handles building the React application.

`runs-on: ubuntu-latest:` Specifies that this job runs on a virtual machine with the latest Ubuntu operating system.
`timeout-minutes: 30:` Sets a 30-minute timeout limit for the job.
`strategy: matrix:` Defines a matrix for testing with different Node.js versions.
`node-version: [16.x, 18.x]:` This tests the build with both Node.js 16.x and 18.x versions.
`steps:` These are the individual actions performed within the job:
`uses: actions/checkout@v3:` Checks out the code from the repository.
`uses: actions/setup-node@v3:` Sets up the specified Node.js version (node-version) in the job runner environment.
`uses: actions/cache@v3:` Caches the node_modules directory based on the operating system, Node.js version, and the hash of the package-lock.json file. This optimizes build times by reusing previously downloaded dependencies.
`run: npm install:` Installs all dependencies listed in the package.json file.
`run: npx eslint .:` Runs ESLint for code analysis.
(Commented out) # npx eslint . --fix: Optionally, this would automatically fix correctable code style issues.
`run: npm run build:` Builds the React application (assuming a build script in package.json). Alternatively, it could use Create React App's built-in build command (npm run build).
`push:` This job deploys the built application to DockerHub.

`runs-on:` ubuntu-latest: Similar to the build job.
`needs: build:` Specifies that this job waits for the build job to complete successfully before proceeding.
`steps:` Actions performed within this job:
`uses: actions/checkout@v4:` Checks out the code from the repository.
`uses: docker/setup-buildx-action@v1:` Sets up Docker Buildx for building container images efficiently.
`uses: docker/login-action@v3:` Logs in to DockerHub using secrets stored in the repository (DOCKERHUB_USERNAME and DOCKERHUB_TOKEN).
`uses: docker/build-push-action@v6:` Builds and pushes the container image to DockerHub.
`context: .:` Uses the current directory as the build context.
`file:` ./Dockerfile: Specifies the Dockerfile used for building the image.
`push: true:` Enables pushing the image to DockerHub.
`tags: ${{ secrets.DOCKERHUB_USERNAME }}/react-app-github-actions:${{github.run_id}}: `Defines the image tag. It includes the username, the application name, and the unique workflow run ID.
update-newtag-in-helm-chart: This job updates the Helm chart with the new Docker image tag.

`runs-on: ubuntu-latest:` Similar to previous jobs.
`needs: push:` This job also requires the successful completion of the push job.
`steps: Actions performed within this job:`
`uses: actions/checkout@v4:` Checks out the code from the repository, using a separate access token (TOKEN).
`run: |: Defines a multi-line shell script:`
sed -i 's/tag: .*/tag: "${{github.run_id}}"/' helm/react-app-chart/values.yaml: Uses the sed command to replace the existing tag value in


## Install helm app 
- cd helm 
- ls 
```
helm install <your-app> ./<your-app-chart>
```
i.e helm install react-app-new ./react-app-chart


## Uninstall Existing helm Release:
If you want to replace the existing installation, uninstall the old release first:
```
helm uninstall react-app-github-actions
```

### check if app running
- kubectl get deployment
- kubectl get svc
- kubectl get ing

## Debug K8s
Basic Debugging Tools 
`kubectl get pods:` List all pods and their status.
`kubectl describe pod <pod-name>:` Provides detailed information about a pod.
`kubectl logs <pod-name>:` View logs from a container within a pod.
`kubectl exec -it <pod-name> <command>:` Execute commands within a running container.
`kubectl port-forward <pod-name> <local-port>:<container-port>:` Forward a local port to a pod's port

### Check pod status:
```
kubectl describe pod react-app-github-actions-5fbd7595b5-rrgm5

```
### Monitor pod events:
```
watch kubectl get events --namespace default

```
### Inspect container logs (if available):
```
kubectl logs react-app-github-actions-5fbd7595b5-rrgm5
```

### Check container image: Ensure that the container image exists
```
docker pull <image-name>:<tag>
```

### Error unauthorized:
incorrect username or password
```
$ docker logout
```
and then pull again. As it is public repo you shouldn't need to login



### NodePort Service:

### Change the service type to NodePort:
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```
or

Edit your service:
```
kubectl edit svc react-app-github-actions
```
### Change the type to NodePort:
type: NodePort


## ArgoCD
### Install Argo CD using manifests

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Access the Argo CD UI (Loadbalancer service) 

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```
## Access the Argo CD UI (Loadbalancer service) -For Windows

```bash
kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'
```

## Get the Loadbalancer service IP
- copy the  nordport from argocd-server
```bash
kubectl get svc argocd-server -n argocd
```
- access the argocd ui on through the  external-ip on your browser

or 

## Get the external cluster ip
- access argo ui with cluster ip and nordport
```
kubectl get nodes -o wide
```
- then copy the external-ip cluster
- then copy the nordport from argocd-server
- access argocd ui on extenal-ip:nordport

## Minikube
### port-forward Access Argo CD UI on Localhost
Forward a local port to the Argo CD server to access the UI on your local machine. For example:
```
kubectl port-forward svc/argocd-server -n argocd 8082:443
```

## Login to Argocd ui
### Log in with the default credentials:
Username:` admin`
Password: You can retrieve it using 
```
 kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

```

or

```
kubectl get secrets -n argocd
```
```
kubectl edit secrets argocd-initial-admin-secret -n argocd
```
- copy the password 
- echo <the password which is in base64 > == | base54 --decode
- copy the decoded password, dont copy with the ' % ' sign

### Note:
 uses a self-signed certificate by default, so you might encounter browser warnings. You can choose to accept the certificate or configure a trusted certificate.
You'll need the admin username and password to log in. The initial admin password is stored in the argocd-initial-admin-secret secret. You can retrieve it using:

```
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

```

### from the ui
- username = "admin"
- password = decoded password

## Deploy your app on ARGOCD
- click on new app
- Application name = i.e go web app
- projet name = default 
- sync policy = automatic
- click on SELF-HEAL
source 
- repository= your github repo and gitlab repo of your code
- revision = HEAD
- select the path i.e helm/go-web-app-chart
Destination
- cluster URL = https://kubernetes.default.svc  # which mean you are deploying on the same k8s cluster
- namespace = default
HELM
- values files = use values.yaml that we provided
- click on create






# .Ensure the Script is Executable
# Before you can run the script, you need to make sure it has executable permissions. To 
```
chmod +x you_file.sh
```


```
#install kubectl
curl https://storage.googleapis.com/kubernetes-release/release/stable.txt > ./stable.txt
export KUBECTL_VERSION=$(cat stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
mkdir -p ~/.kube
ln -sf "/mnt/c/users/$USER/.kube/config" ~/.kube/config
rm ./stable.txt 

```

# ### Kubeconfig
# #download the Kubeconfig from digitalocean manuel setup
```
rm -rf $HOME/.kube/config
mkdir -p $HOME/.kube
sudo cp ~/k8s-cluster-kubeconfig.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```‣敲捡彴灡彰牡潧摣⌊ 爀攀愀挀琀开愀瀀瀀开愀爀最漀挀搀ഀ਀�