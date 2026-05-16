#GitOps CI/CD

Projekt kierunkowy pokazujący automatyzację wdrażania aplikacji Kubernetes z użyciem GitHub Actions, Azure, Terraform, Argo CD i Jsonnet.

## Cel Projektu

Repozytorium prezentuje pełny proces GitOps:

```text
commit w GitHub
-> testy i build w GitHub Actions
-> publikacja obrazu Docker w Azure Container Registry
-> aktualizacja konfiguracji GitOps
-> synchronizacja Argo CD
-> wdrożenie aplikacji w AKS
```

## Struktura

```text
demo-app-repo      aplikacja Node.js, testy, Dockerfile
gitops-repo        Argo CD ApplicationSet, Jsonnet, Helm values
terraform/azure    AKS, ACR, Argo CD, NGINX Ingress, GitHub OIDC
.github/workflows  pipeline CI/CD i Terraform
```

## Główne Workflow

- `full-bootstrap-deploy.yml` - tworzy infrastrukturę, buduje obraz i wdraża aplikację.
- `app-ci-cd.yml` - buduje nową wersję aplikacji i aktualizuje GitOps.
- `terraform-azure.yml` - wykonuje `plan`, `apply` i `destroy` infrastruktury Azure.

## Bootstrap

Do pierwszego uruchomienia wymagany jest jeden sekret GitHub:

```text
BOOTSTRAP_CREDENTIALS
```

Format:

```json
{
  "azure_client_id": "...",
  "azure_client_secret": "...",
  "azure_tenant_id": "...",
  "azure_subscription_id": "...",
  "github_token": "..."
}
```

Workflow sam wygeneruje i zapisze kolejne sekrety oraz zmienne repozytorium potrzebne do OIDC, ACR i GitOps.

Przed uruchomieniem należy dodać zmienne:

```text
TF_STATE_RESOURCE_GROUP
TF_STATE_LOCATION
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
TF_STATE_KEY
ACR_NAME
```

## Uruchomienie

1. Utworzyć repozytorium GitHub.
2. Dodać `BOOTSTRAP_CREDENTIALS`.
3. Dodać wymagane zmienne repozytorium.
4. Wypchnąć kod do gałęzi `main`.
5. Uruchomić workflow `Full Bootstrap And Deploy`.
6. Sprawdzić w GitHub Actions linki do Argo CD i aplikacji.

## Lokalne Sprawdzenie

```bash
cd demo-app-repo
npm install
npm run lint
npm test
```

```bash
cd ../gitops-repo
jsonnet --jpath app-generator \
  --ext-str envs_file=dev \
  --ext-str env='' \
  --ext-str repo_url='https://github.com/Pok1s/jsonnet-gitops-diploma.git' \
  app-generator/app-generator-list.jsonnet
```

```bash
cd ../terraform/azure
terraform init -backend=false
terraform validate
```

## Zasoby Kubernetes

Projekt wdraża:

- Namespace
- Deployment
- Service
- Ingress
- ConfigMap
- Secret
- HorizontalPodAutoscaler

Środowiska: `dev`, `stage`, `prod`.

## Scenariusz Demo

1. Pokazać repozytorium i strukturę projektu.
2. Uruchomić GitHub Actions pipeline.
3. Pokazać obraz w Azure Container Registry.
4. Pokazać commit z aktualizacją GitOps.
5. Pokazać aplikację Argo CD jako `Synced` i `Healthy`.
6. Pokazać zasoby Kubernetes.
7. Otworzyć aplikację w przeglądarce.

