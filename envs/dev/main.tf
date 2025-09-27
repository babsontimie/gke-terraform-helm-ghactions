provider "google" {
  project = var.project-id
  region  = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "gke" {
  source       = "../../modules/gke"
  cluster_name = var.cluster_name
  location     = var.location
  network      = var.network
  subnetwork   = var.subnetwork
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
