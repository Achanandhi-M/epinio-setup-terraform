provider "helm" {
  kubernetes {
    config_path = "kubeconfig"
  }
}

provider "kubectl" {
  config_path = "kubeconfig"
}

// ingress
resource "helm_release" "ingress" {
  name       = "nginx-ingress"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  version    = "11.3.18"
  timeout    = 600
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cert-manager"
  version    = "1.3.16"
  namespace  = "cert-manager"
  set {
    name  = "installCRDs"
    value = true
  }
  timeout          = 600
  create_namespace = true
}

// certificate issuer
resource "kubectl_manifest" "cluster_issuer" {
  yaml_body  = templatefile("${path.module}/cert-issuer.yaml.tpl", { email = var.email })
  depends_on = [helm_release.cert_manager]
}

// epinio
resource "helm_release" "epinio" {
  name             = "epinio"
  repository       = "https://epinio.github.io/helm-charts"
  chart            = "epinio"
  version          = "1.11.1"
  namespace        = "epinio"
  timeout          = 600
  create_namespace = true
  depends_on       = [kubectl_manifest.cluster_issuer]

  set {
    name  = "global.domain"
    value = var.global_domain
  }

  set {
    name  = "global.tlsIssuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "global.tlsIssuerEmail"
    value = var.email
  }

  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }

}
