# gke-terraform-helm-ghactions
gke-terraform-helm-ghactions

Creating a Terraform configuration for multiple environments to provision a GKE cluster and deploy various services and tools like Helm, ArgoCD, Ingress, Prometheus, Secret Manager, Kubernetes provider, and a basic CI/CD pipeline with GitHub Actions is a complex but powerful setup.

I'll give you a modular and environment-friendly Terraform setup that you can use across environments like dev, staging, and prod.

✅ Technologies Covered

Google Kubernetes Engine (GKE)

Google Secret Manager

Helm

ArgoCD

Ingress (NGINX)

Prometheus (via Helm)

GitHub Actions (CI/CD)

Sample Kubernetes Deployment

Environment Isolation (dev, staging, prod)

🧱 Project Structure
```terraform-gke-infra/
├── envs/
│   ├── dev/
│   │   └── main.tf
│   │   └── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       └── main.tf
│       └── backend.tf
│       └── terraform.tfvars
├── modules/
│   ├── gke/
│   ├── helm/
│   ├── argocd/
│   ├── ingress/
│   ├── prometheus/
│   ├── secrets/
│   └── k8s-deployment/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml
├── README.md
```
```
🧩 1. Modules

We'll start with the reusable modules.

🔹 modules/gke/main.tf
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.location
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
```
```
# variables.tf
variable "cluster_name" {}
variable "location" {}
variable "network" {}
variable "subnetwork" {}
variable "node_count" {}
```

🔹 modules/helm/main.tf
```
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"
  namespace  = "ingress-nginx"

  create_namespace = true
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

  create_namespace = true
}

variable "kubeconfig_path" {}
```

🔹 modules/argocd/main.tf
```
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "5.47.0"

  create_namespace = true
}
```
🔹 modules/secrets/main.tf
```
resource "google_secret_manager_secret" "example" {
  secret_id = var.secret_name
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = var.secret_value
}

variable "secret_name" {}
variable "secret_value" {}
```
🔹 modules/k8s-deployment/main.tf
```
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "hello-app"
    namespace = "default"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hello"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello"
        }
      }

      spec {
        container {
          name  = "hello-container"
          image = "gcr.io/google-samples/hello-app:1.0"
          ports {
            container_port = 8080
          }
        }
      }
    }
  }
}
```
🌍 2. Environments

🔹 envs/dev/main.tf
```
provider "google" {
  project = "your-dev-project"
  region  = "us-central1"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "gke" {
  source       = "../../modules/gke"
  cluster_name = "dev-cluster"
  location     = "us-central1"
  network      = "default"
  subnetwork   = "default"
  node_count   = 2
}

module "helm" {
  source          = "../../modules/helm"
  kubeconfig_path = "~/.kube/config"
}

module "argocd" {
  source = "../../modules/argocd"
}

module "secrets" {
  source       = "../../modules/secrets"
  secret_name  = "example-secret"
  secret_value = "supersecret123"
}

module "k8s_deployment" {
  source = "../../modules/k8s-deployment"
}
```
🔹 envs/dev/backend.tf
```
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "dev"
  }
}
```
🔹 envs/dev/terraform.tfvars
```
# Leave empty or use for overriding variables
```
🔁 3. GitHub Actions for CI/CD
📁 .github/workflows/ci-cd.yaml
```
name: Deploy to GKE

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    name: Deploy to GKE
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Google Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
        with:
          project_id: ${{ secrets.GCP_PROJECT }}
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          export_default_credentials: true

      - name: Authenticate Docker
        run: gcloud auth configure-docker

      - name: Build & Push Docker Image
        run: |
          docker build -t gcr.io/${{ secrets.GCP_PROJECT }}/hello-app:latest .
          docker push gcr.io/${{ secrets.GCP_PROJECT }}/hello-app:latest

      - name: Set KUBECONFIG
        run: |
          gcloud container clusters get-credentials dev-cluster --region us-central1

      - name: Apply Kubernetes Manifests
        run: |
          kubectl apply -f k8s/sample-deployment.yaml
```
📄 k8s/sample-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
        - name: hello
          image: gcr.io/YOUR_PROJECT_ID/hello-app:latest
          ports:
            - containerPort: 8080
```
✅ Steps to Use

Configure GCP project & enable APIs

Create GCS bucket for Terraform backend

Initialize & apply Terraform for your environment:

cd envs/dev
terraform init
terraform apply


Configure GitHub secrets:

GCP_PROJECT

GCP_SA_KEY (Base64 or raw JSON of service account key)
```

📌 Notes

Use terragrunt if you want DRY management across environments.

Add ArgoCD App resources to point to GitHub repo for GitOps.

Secure secrets using External Secrets Operator
.
