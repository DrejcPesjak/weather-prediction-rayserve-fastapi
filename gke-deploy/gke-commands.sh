# More info about RayServe Kubernetes deployment
# https://docs.ray.io/en/latest/serve/production-guide/kubernetes.html
# https://docs.ray.io/en/master/cluster/kubernetes/k8s-ecosystem/ingress.html#kuberay-ingress
# https://github.com/ray-project/kuberay/tree/master/ray-operator/config/samples

# Authentication with Google Cloud
gcloud auth list
gcloud auth login
gcloud iam service-accounts get-iam-policy drejc-rso-new@balmy-apogee-404909.iam.gserviceaccount.com

# Listing and setting Google Cloud projects
gcloud projects list --sort-by=projectId --limit=5
gcloud config set project balmy-apogee-404909

# Listing existing container clusters
gcloud container clusters list

# Create a new cluster (use GoogleCloudConsole Web UI with specified settings)
gcloud beta container --project "balmy-apogee-404909" clusters create-auto "rayserve-cluster" \
	--region "europe-central2" \
	--release-channel "regular" \
	--network "projects/balmy-apogee-404909/global/networks/default" \
	--subnetwork "projects/balmy-apogee-404909/regions/europe-central2/subnetworks/default" \
	--cluster-ipv4-cidr "/17" \
	--binauthz-evaluation-mode=DISABLED

# Getting credentials for the new cluster
gcloud container clusters get-credentials rayserve-cluster --zone europe-central2

# Helm setup for Kuberay
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install kuberay-operator kuberay/kuberay-operator --version 1.0.0
kubectl get pods

# Install and verify raycluster
helm install raycluster kuberay/ray-cluster --version 1.0.0
kubectl get rayclusters
kubectl get pods
kubectl get pods --selector=ray.io/cluster=raycluster-kuberay

# Setting up service account for Kubernetes
kubectl create serviceaccount k8s-drejc
kubectl annotate serviceaccount k8s-drejc "iam.gke.io/gcp-service-account=drejc-rso-new@balmy-apogee-404909.iam.gserviceaccount.com"
kubectl get serviceAccounts
kubectl describe serviceaccount k8s-drejc

# IAM policy binding for the service account
gcloud iam service-accounts add-iam-policy-binding \
	drejc-rso-new@balmy-apogee-404909.iam.gserviceaccount.com \
	--role roles/iam.workloadIdentityUser \
	--member "serviceAccount:balmy-apogee-404909.svc.id.goog[default/k8s-drejc]"

# Deploy RayServe and manage services
kubectl apply -f gke-deploy/ray-service.weather-prediction.yaml
kubectl get pods
kubectl get services

# Automatically updating service names in the ingress configuration
SERVICE_NAME=$(kubectl get services | grep 'prediction-raycluster.*head-svc' | awk '{print $1}')
sed -i "s|name:.*raycluster.*head-svc|name: $SERVICE_NAME|" gke-deploy/ray-cluster-gclb-ingress.yaml

# Setting up a subnet (use GoogleCloudConsole Web UI if lacking permissions)
gcloud compute networks subnets create proxy-only-subnet-01 \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE \
  --region=europe-central2 \
  --network=default \
  --range=10.10.0.0/23

# Applying backend configurations and ingress setup
kubectl apply -f gke-deploy/ray-hc-backendconfig.yaml
kubectl get backendconfigs
kubectl annotate service rvice-weather-prediction-raycluster-5phmv-head-svc \
	beta.cloud.google.com/backend-config='{"default": "ray-serve-backend-config"}'
kubectl apply -f gke-deploy/ray-cluster-gclb-ingress.yaml
kubectl get ingress ray-cluster-ingress
kubectl describe ingress ray-cluster-ingress
