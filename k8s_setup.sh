# !/bin/bash
# .Ensure the Script is Executable
# Before you can run the script, you need to make sure it has executable permissions. To 
# chmod +x you_file.sh
set -e  # Exit immediately if a command exits with a non-zero status
sudo apt update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade  -y

#install kubectl
curl https://storage.googleapis.com/kubernetes-release/release/stable.txt > ./stable.txt
export KUBECTL_VERSION=$(cat stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
mkdir -p ~/.kube
ln -sf "/mnt/c/users/$USER/.kube/config" ~/.kube/config
rm ./stable.txt 


### install helm From Apt (Debian/Ubuntu)
echo "--------------------helm--------------------"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update  -y
sudo apt-get install helm  -y
echo "--------------------helm--------------------"


### create ingress-controller
#Run the kubectl command to create a namespace:
kubectl create namespace ingress-nginx
#Run the command to add the helm repository for the nginx Controller:
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#Run the command to update the helm repository data:
helm repo update
kubectl get all -n ingress-nginx

#4. Run the command to install the Controller: in helm app
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f helm/react-app-chart/values.yaml
#
# kubectl delete namespace ingress-nginx



## ArgoCD
### Install Argo CD using manifests
echo "--------------------argocd--------------------"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
## ArgoCD password
echo "--------------------Argocd password--------------------"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d




#Steps to Install Prometheus:
echo "--------------------Prometheus--------------------"
kubectl create namespace prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update 
helm install prometheus prometheus-community/prometheus
kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-ext
# minikube service prometheus-server-ext
echo "prometheus installed and started successfully!"
# Prometheus password
echo "--------------------Prometheus password--------------------"
kubectl get secret --namespace default prometheus -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


#Steps to install Grafana:
echo "--------------------Grafana--------------------"
kubectl create namespace grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana
kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-ext
# minikube service grafana-ext
echo "granfana installed and started successfully!"

# To get user name and password in Grafana:

# kubectl get secret --namespace default grafana -o yaml
# echo "RkpwY21aTFNXRDVJN3Z4RWFFUjlibkV1SDBDbnFBendadmc0bmROZQ==" | openssl base64 -d ; echo

# or 
echo "--------------------Grafana password--------------------"
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

#Verify Secret Name and Namespace:
# kubectl get secrets --namespace default to list all secrets in the "default" namespace. Check if a secret with a similar name exists.
#If you find a matching secret, replace "prometheus" with the correct name in your command.
#Check for the Secret in Other Namespaces:
#If you're unsure about the namespace, use kubectl get secrets -A to list secrets across
