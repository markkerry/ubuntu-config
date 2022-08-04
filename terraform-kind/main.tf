terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "server" {
  type = string
}

variable "client_certificate_data" {
  type = string
}

variable "client_key_data" {
  type = string
}

variable "certificate_authority_data" {
  type = string
}

provider "kubernetes" {
  host = var.server

  client_certificate     = base64decode(var.client_certificate_data)
  client_key             = base64decode(var.client_key_data)
  cluster_ca_certificate = base64decode(var.certificate_authority_data)
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "kind-nginx-demo"
    labels = {
      App = "KindNginxDemo"
    }
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        App = "KindNginxDemo"
      }
    }
    template {
      metadata {
        labels = {
          App = "KindNginxDemo"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "nginx" {
  metadata {
    name = "kind-nginx-demo"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30001
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

