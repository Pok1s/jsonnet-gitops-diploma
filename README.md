# Diploma GitOps CI/CD Demo

Production-style demo for CI/CD automation with GitHub Actions, Azure Container Registry, Argo CD, ApplicationSet, Jsonnet and Helm.

Structure:

- `demo-app-repo` - test Node.js web app, Dockerfile and GitHub Actions pipeline.
- `gitops-repo` - Argo CD ApplicationSet flow based on `argocd-workloads`, reduced to one demo application.
- `terraform/azure` - Azure infrastructure: resource group, VNet, AKS, ACR, GitHub OIDC, Argo CD, Image Updater and NGINX Ingress.

Main flow:

```text
push to GitHub
-> GitHub Actions tests, builds and pushes Docker image
-> workflow updates GitOps Helm values
-> Argo CD ApplicationSet runs Jsonnet app-generator
-> generated Application deploys Helm chart to Kubernetes
```

Infrastructure flow:

```text
GitHub Actions terraform workflow
-> Azure OIDC login
-> terraform plan/apply
-> AKS + ACR + Argo CD + Image Updater + NGINX Ingress
```

Only one manual GitHub secret is required for bootstrap:

```text
BOOTSTRAP_CREDENTIALS
```

After `bootstrap-apply`, the workflow writes generated Azure/GitOps secrets and variables back to GitHub automatically.

Local checks:

```bash
cd demo-app-repo
npm install
npm test

cd ../gitops-repo
jsonnet --ext-str envs_file=dev --ext-str env='' app-generator/app-generator-list.jsonnet
helm lint charts/service -f values/diploma-demo/common.yaml -f values/diploma-demo/demo-web/values-dev.yaml

cd ../terraform/azure
terraform init
terraform validate
```
