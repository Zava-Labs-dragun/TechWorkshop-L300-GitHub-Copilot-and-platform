# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service.

## How authentication works

The workflow uses **GitHub Actions OIDC federated credentials**. GitHub exchanges a short-lived OIDC token with Azure Entra ID at runtime — no passwords, client secrets, or `AZURE_CREDENTIALS` JSON are stored anywhere in GitHub.

## Step 1: Create an Entra app registration with federated credentials

Run these commands once:

```powershell
# 1. Create the app registration and service principal
$app = az ad app create --display-name "github-actions-zavastore" | ConvertFrom-Json
az ad sp create --id $app.appId

# 2. Federated credential for the main branch
az ad app federated-credential create --id $app.appId --parameters `
  '{"name":"github-main","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Zava-Labs-dragun/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'

# 3. Federated credential for the dev branch
az ad app federated-credential create --id $app.appId --parameters `
  '{"name":"github-dev","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Zava-Labs-dragun/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/dev","audiences":["api://AzureADTokenExchange"]}'

# 4. Assign Contributor on the resource group
$spId = az ad sp show --id $app.appId --query id -o tsv
az role assignment create --assignee $spId --role Contributor `
  --scope /subscriptions/2ece4124-9e0b-4657-bd8f-fa47cc3fa359/resourceGroups/rg-zavastore-dev-westus3

# 5. Assign AcrPush on the Container Registry
az role assignment create --assignee $spId --role AcrPush `
  --scope /subscriptions/2ece4124-9e0b-4657-bd8f-fa47cc3fa359/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/acrzavastoredevqkitki

# 6. Print the three values needed in Step 2
Write-Host "AZURE_CLIENT_ID:       $($app.appId)"
Write-Host "AZURE_TENANT_ID:       $(az account show --query tenantId -o tsv)"
Write-Host "AZURE_SUBSCRIPTION_ID: 2ece4124-9e0b-4657-bd8f-fa47cc3fa359"
```

## Step 2: Add required GitHub repository variables

Go to **Settings → Secrets and variables → Actions → Variables** (not Secrets) and add all six:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | Output from Step 1 |
| `AZURE_TENANT_ID` | Output from Step 1 |
| `AZURE_SUBSCRIPTION_ID` | `2ece4124-9e0b-4657-bd8f-fa47cc3fa359` |
| `AZURE_CONTAINER_REGISTRY_NAME` | `acrzavastoredevqkitki` |
| `AZURE_APP_SERVICE_NAME` | `app-zavastore-dev-qkitki` |
| `AZURE_RESOURCE_GROUP` | `rg-zavastore-dev-westus3` |

> No values go under the **Secrets** tab. All six are plain **Variables**.

## Workflow behavior

Triggers:
- Push to `main` or `dev` when files under `src/` change
- Pull request to any branch (build + deploy runs without merge)
- Manual trigger via **Actions → Run workflow**

Stages:
1. `az acr build` — uploads source to Azure and builds the Docker image in the cloud (no local Docker required)
2. Image pushed to ACR with two tags: `<sha>` and implicitly available as latest
3. `az webapp config container set` — updates the App Service to run the new image

## Acceptance criteria

- No references to `AZURE_CREDENTIALS` or secrets-based login exist in this workflow.
- All six required variables are listed above under **Variables** (not Secrets).
- RBAC: service principal has **Contributor** on the resource group and **AcrPush** on the ACR.
- The workflow runs on a PR to `main` without requiring a merge, and performs: login → build → push → deploy.


Run these commands once:

```powershell
# 1. Create the app registration and service principal
$app = az ad app create --display-name "github-actions-zavastore" | ConvertFrom-Json
az ad sp create --id $app.appId

# 2. Add federated credential for the main branch
az ad app federated-credential create --id $app.appId --parameters `
  '{"name":"github-main","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Zava-Labs-dragun/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'

# 3. Add federated credential for the dev branch
az ad app federated-credential create --id $app.appId --parameters `
  '{"name":"github-dev","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Zava-Labs-dragun/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/dev","audiences":["api://AzureADTokenExchange"]}'

# 4. Assign Contributor on the resource group
$spId = az ad sp show --id $app.appId --query id -o tsv
az role assignment create --assignee $spId --role Contributor `
  --scope /subscriptions/2ece4124-9e0b-4657-bd8f-fa47cc3fa359/resourceGroups/rg-zavastore-dev-westus3

# 5. Assign AcrPush on the Container Registry
az role assignment create --assignee $spId --role AcrPush `
  --scope /subscriptions/2ece4124-9e0b-4657-bd8f-fa47cc3fa359/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/acrzavastoredevqkitki

# 6. Print the values you need for Step 2
Write-Host "AZURE_CLIENT_ID:       $($app.appId)"
Write-Host "AZURE_TENANT_ID:       $(az account show --query tenantId -o tsv)"
Write-Host "AZURE_SUBSCRIPTION_ID: 2ece4124-9e0b-4657-bd8f-fa47cc3fa359"
```

## Step 2: Add GitHub repository variables

Go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | Output from Step 1 |
| `AZURE_TENANT_ID` | Output from Step 1 |
| `AZURE_SUBSCRIPTION_ID` | `2ece4124-9e0b-4657-bd8f-fa47cc3fa359` |
| `AZURE_CONTAINER_REGISTRY_NAME` | `acrzavastoredevqkitki` |
| `AZURE_APP_SERVICE_NAME` | `app-zavastore-dev-qkitki` |
| `AZURE_RESOURCE_GROUP` | `rg-zavastore-dev-westus3` |

## How to configure secrets and variables

1. Go to your GitHub repository
2. Click on **Settings → Secrets and variables → Actions**
3. Add `AZURE_CREDENTIALS` under the **Secrets** tab
4. Add the variables under the **Variables** tab

## Service principal permissions

The service principal needs the following permissions:

- **Contributor** role on the resource group (for App Service deployment)
- **AcrPush** role on the Azure Container Registry (for pushing container images)

To assign the ACR role:

```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/2ece4124-9e0b-4657-bd8f-fa47cc3fa359/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/acrzavastoredevqkitki
```

## Workflow behavior

The workflow triggers on:
- Push to `main` or `dev` branch (when `src/` changes)
- Pull requests to any branch
- Manual trigger via GitHub UI

The workflow will:
1. Build your .NET application as a Docker container using `az acr build` (no local Docker required)
2. Push the container to Azure Container Registry
3. Deploy the container to Azure App Service

## Finding your resource names

```bash
# List resources in your resource group
az resource list --resource-group rg-zavastore-dev-westus3 --output table
```

Look for resources with types:
- `Microsoft.ContainerRegistry/registries` → ACR name
- `Microsoft.Web/sites` → App Service name
