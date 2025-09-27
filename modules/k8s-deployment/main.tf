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
