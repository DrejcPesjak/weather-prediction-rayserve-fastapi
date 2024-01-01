
# Weather Prediction with Ray Serve and FastAPI

This project serves a weather prediction model using Ray Serve and FastAPI, developed as part of a cloud computing university course (RSO).

## Running Locally

To run the application locally, follow these steps:

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Set Google Application Credentials**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/credentials.json
   ```

3. **Start Ray Serve Application**:
   ```bash
   serve run rayserve_model:model_predictor
   ```

## Docker Deployment (Currently not working)
To build and run a Docker image (note: this functionality is currently not operational):
```bash
# Build the Docker image
# docker build -t weather-pred-ray .

# Run the Docker container on port 8000
# docker run -p 8000:8000 weather-pred-ray
```

## Deploying to Google Kubernetes Engine (GKE)

For detailed setup commands, see [GKE Commands](gke-deploy/gke-commands.sh).

Also refer to Ray.Io docs for more info:
- [RayServe Kubernetes Deployment Guide](https://docs.ray.io/en/latest/serve/production-guide/kubernetes.html)
- [RayServe Kubernetes Ingress Guide](https://docs.ray.io/en/master/cluster/kubernetes/k8s-ecosystem/ingress.html#kuberay-ingress)
- [Kuberay GitHub Repository - Samples](https://github.com/ray-project/kuberay/tree/master/ray-operator/config/samples)



### Initial Setup
1. **List Google Cloud Projects**:
   ```bash
   gcloud projects list --sort-by=projectId --limit=5
   ```

2. **Set Desired Project**:
   ```bash
   gcloud config set project balmy-apogee-404909
   ```

3. **Check Existing Kubernetes Clusters or Create a New One**:
   ```bash
   gcloud container clusters list
   # Create a new cluster if necessary
   ```

4. **Get Credentials for Kubernetes Cluster**:
   ```bash
   gcloud container clusters get-credentials rayserve-cluster --zone europe-central2
   ```

5. **Install Helm and Configure Ray Helm Chart Repository**:
   ```bash
   helm repo add kuberay https://ray-project.github.io/kuberay-helm/
   helm repo update
   ```

### Deploying the Application
1. **Install KubeRay Operator**:
   ```bash
   helm install kuberay-operator kuberay/kuberay-operator --version 1.0.0
   ```

2. **Verify Operator is Running**:
   ```bash
   kubectl get pods
   ```

3. **Install RayCluster**:
   ```bash
   helm install raycluster kuberay/ray-cluster --version 1.0.0
   ```

4. **Verify RayCluster Status**:
   ```bash
   kubectl get rayclusters
   ```

5. **Apply RayService Configuration**:
   ```bash
   kubectl apply -f gke-deploy/ray-service.weather-prediction.yaml
   ```

### Additional Configuration
1. **Create and Annotate a Service Account for Workload Identity**:
   ```bash
   kubectl create serviceaccount k8s-drejc
   kubectl annotate serviceaccount k8s-drejc "iam.gke.io/gcp-service-account=drejc-rso-new@balmy-apogee-404909.iam.gserviceaccount.com"
   ```

2. **Add IAM Policy Binding for Service Account**:
   ```bash
   gcloud iam service-accounts add-iam-policy-binding \
      drejc-rso-new@balmy-apogee-404909.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:balmy-apogee-404909.svc.id.goog[default/k8s-drejc]"
   ```

3. **Create a Proxy-Only Subnet if Required**:
   ```bash
   gcloud compute networks subnets create proxy-only-subnet-01 \
      --purpose=REGIONAL_MANAGED_PROXY \
      --role=ACTIVE \
      --region=europe-central2 \
      --network=default \
      --range=10.10.0.0/23
   ```

4. **Apply BackendConfig for Health Checks**:
   ```bash
   kubectl apply -f gke-deploy/ray-hc-backendconfig.yaml
   ```

5. **Annotate the Service for BackendConfig**:
   ```bash
   kubectl annotate service rvice-weather-prediction-raycluster-5phmv-head-svc beta.cloud.google.com/backend-config='{"default": "ray-serve-backend-config"}'
   ```

6. **Apply Ingress Configuration**:
   ```bash
   kubectl apply -f gke-deploy/ray-cluster-gclb-ingress.yaml
   ```

### Verification and Troubleshooting
- **Check All Pods are Running**:
  ```bash
  kubectl get pods
  ```

- **Verify Services and Their ClusterIP**:
  ```bash
  kubectl get svc
  ```

- **Inspect Ingress and Ensure External IP if Public Access is Desired**:
  ```bash
  kubectl get ingress ray-cluster-ingress
  ```

- **Troubleshooting**: Use `kubectl describe` and GCP Console to check load balancers, firewall rules, quotas, etc.

### Notes
- Order of operations is crucial. Ensure BackendConfig is applied before annotating the service and then applying the Ingress configuration.
- Make sure that pods have status "running" after executing kubectl commands it might take up to 15 minutes to spin up some of these pods.
- For public access, use the `gce` ingress class in your Ingress configuration to create an external HTTP(S) load balancer.
- Ensure your application is secured appropriately when exposed publicly.
