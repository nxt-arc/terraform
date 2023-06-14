# this configures required providers
terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

# configure a helm provider.  helm provider uses this .kube config file to
# know which cluster to connect to
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# for larger tf projects you'd want this in a separate file but it's literally the only one
# so its just right here
variable "admin_password" {}


# helm is whatever, but the easiest way to install argo is with this helm chart
# defining the admin_password variable in variables.tf will prompt for its entry on the commandline
module "argocd" {
  source         = "aigisuk/argocd/kubernetes"
  admin_password = var.admin_password
}

data "kubectl_file_documents" "root-app" {
  content = file("./root-app.yml")
}

resource "kubectl_manifest" "root-app" {
  depends_on = [
    module.argocd,
  ]
  count     = length(data.kubectl_file_documents.root-app.documents)
  yaml_body = element(data.kubectl_file_documents.root-app.documents, count.index)
  override_namespace = "argocd"
}

# terraform destroy doesn't work because I don't know why yet, but you can delete the argo namespace with --force
# update It didn't work because I didn't configure a stable 'state' repository.  TF writes (what it thinks) the current
# 'state' should be a file instead of querying the system like I thought it would.
