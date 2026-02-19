# ZavaStorefront – Azure Infrastructure

Provisions all Azure resources for the **ZavaStorefront** ASP.NET Core MVC application (dev environment) using **Bicep** and **Azure Developer CLI (azd)**.

## Architecture

```
rg-zavastore-dev-westus3
├── Azure Container Registry (Basic)      – container images
├── App Service Plan (Linux B1)           – hosting runtime
├── Web App for Containers (Linux)        – app host
│     └── System-assigned managed identity → AcrPull on ACR
├── Log Analytics Workspace               – telemetry sink
├── Application Insights                  – monitoring
└── AI Foundry Hub + Project              – GPT-4 & Phi access
      └── AI Services (CognitiveServices)
            ├── gpt-4 (turbo-2024-04-09)
            └── Phi-3-mini-128k-instruct
```

All resources are deployed to **westus3** (required for GPT-4 and Phi model availability).

## Repository layout

```
infra/
├── main.bicep                  # Orchestration template
├── main.parameters.bicepparam  # Default parameter values
└── modules/
    ├── acr.bicep               # Azure Container Registry
    ├── appserviceplan.bicep    # Linux App Service Plan
    ├── webapp.bicep            # Web App for Containers
    ├── roleassignment.bicep    # AcrPull role on ACR
    ├── appinsights.bicep       # App Insights + Log Analytics
    └── aifoundry.bicep         # AI Foundry Hub, Project & models
src/
└── Dockerfile                  # Multi-stage .NET 6 image
azure.yaml                      # azd project configuration
.github/workflows/
└── acr-build-push.yml          # CI: cloud build + ACR push (no local Docker)
```

## First-time deployment

### Prerequisites
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) ≥ 2.60
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)

### Steps

```bash
# 1. Login
az login
azd auth login

# 2. Initialise azd environment (creates .azure/<env-name>/)
azd env new dev

# 3. Set target subscription and location
azd env set AZURE_LOCATION westus3

# 4. Provision all resources
azd provision

# 5. Build and push the image (cloud build – no local Docker required)
az acr build \
  --registry <acrName> \
  --image zavastore:latest \
  --file src/Dockerfile \
  src/

# 6. Deploy the app
azd deploy
```

The `azd provision` step creates the resource group `rg-zavastore-dev-westus3` automatically.

## CI / CD

The GitHub Actions workflow [.github/workflows/acr-build-push.yml](.github/workflows/acr-build-push.yml) triggers on every push to `main` that touches `src/`. It uses `az acr build` to build and push the image entirely in the cloud — **no local Docker installation required**.

### Required GitHub repository variables

| Variable | Example value |
|---|---|
| `AZURE_CLIENT_ID` | OIDC app registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `ACR_NAME` | `acrzavastoredeve12345` |

Set up a [federated credential](https://learn.microsoft.com/entra/workload-id/workload-identity-federation-create-trust) on the app registration for the repository.

## Cost notes (dev)

| Resource | SKU | Estimated cost |
|---|---|---|
| ACR | Basic | ~$5/month |
| App Service Plan | B1 Linux | ~$13/month |
| Log Analytics | Pay-per-GB (30-day retention) | minimal for dev |
| Application Insights | Pay-per-GB | minimal for dev |
| AI Services | S0 standard | pay-per-call |

Set `alwaysOn: false` on the Web App (already set) to reduce B1 costs.

## Security

- ACR admin access is **disabled**; the Web App pulls images using its system-assigned managed identity (`AcrPull` role).
- No passwords or secrets required for container pulls.
- All HTTPS is enforced (`httpsOnly: true`).
- Key Vault is provisioned for AI Foundry with RBAC authorization and soft-delete enabled.
