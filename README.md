# Weather Prediction with Ray Serve and FastAPI

This project serves a weather prediction model using Ray Serve and FastAPI, developed as part of a cloud computing university course (RSO).

## Running Locally

To run the application locally, follow these steps:

1. Install the required dependencies:

   ```
   pip install -r requirements.txt
   ```

2. Set the Google Application Credentials environment variable to point to your JSON credentials file:

   ```
   export GOOGLE_APPLICATION_CREDENTIALS=/home/drew99/School/RSO/balmy-apogee-404909-3d6e10b65c43.json
   ```

3. Start the Ray Serve application:

   ```
   serve run rayserve_model:model_predictor
   ```

## Docker Deployment (Note: Currently not working)

To build a Docker image for deployment, you can use the following commands:

```bash
# Build the Docker image (Currently not working)
# docker build -t weather-pred-ray .

# Run the Docker container on port 8000 (Currently not working)
# docker run -p 8000:8000 weather-pred-ray
```

## Deploying to Google Kubernetes Engine (GKE)

To deploy the application to Google Kubernetes Engine (GKE), follow these steps:

1. List your Google Cloud projects and set the desired project:

   ```bash
   gcloud projects list --sort-by=projectId --limit=5
   gcloud config set project balmy-apogee-404909
   ```

2. Check the existing Kubernetes clusters or create a new one (e.g., `rayserve-cluster`) on GCP:

   ```bash
   gcloud container clusters list
   ```

3. Get credentials for your Kubernetes cluster:

   ```bash
   gcloud container clusters get-credentials rayserve-cluster --zone europe-central2
   ```

4. Install Helm and configure the Ray Helm chart repository:

   ```bash
   # Install Helm
   helm repo add kuberay https://ray-project.github.io/kuberay-helm/
   helm repo update
   ```

5. Install the KubeRay operator:

   ```bash
   helm install kuberay-operator kuberay/kuberay-operator --version 1.0.0
   ```

6. List the pods to ensure the operator is running:

   ```bash
   kubectl get pods
   ```

7. Install the RayCluster using Helm:

   ```bash
   helm install raycluster kuberay/ray-cluster --version 1.0.0
   ```

8. Check the status of the RayCluster:

   ```bash
   kubectl get rayclusters
   ```

9. Verify that the pods for RayCluster are running:

   ```bash
   kubectl get pods --selector=ray.io/cluster=raycluster-kuberay
   ```

10. Apply the Kubernetes configuration file for your RayService (e.g., `ray-service.weather-prediction.yaml`):

    ```bash
    kubectl apply -f ray-service.weather-prediction.yaml
    ```

Now, your Weather Prediction application should be deployed and accessible on GKE.
