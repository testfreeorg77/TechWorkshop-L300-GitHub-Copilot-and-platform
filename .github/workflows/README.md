# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service using **Federated Identity (OIDC)** for secure authentication.

## Prerequisites

The workflow uses **OpenID Connect (OIDC)** for authentication with Azure, which is more secure than using secrets.

### Required GitHub Variables

All variables have been configured in **Settings → Secrets and variables → Actions → Variables**:

### Required GitHub Variables

All variables have been configured in **Settings → Secrets and variables → Actions → Variables**:

1. **AZURE_CLIENT_ID** - The Application (client) ID of the Azure AD app
2. **AZURE_TENANT_ID** - The Azure AD tenant ID
3. **AZURE_SUBSCRIPTION_ID** - Your Azure subscription ID
4. **AZURE_CONTAINER_REGISTRY_NAME** - The name of your Azure Container Registry (without .azurecr.io)
5. **AZURE_APP_SERVICE_NAME** - The name of your Azure App Service
6. **AZURE_RESOURCE_GROUP** - The name of your Azure Resource Group

## ✅ Configuration Status

All required variables and federated credentials have been configured:
- ✅ Azure AD Application created
- ✅ Service Principal created with Contributor role
- ✅ ACR Push permissions assigned
- ✅ Federated credentials configured for GitHub Actions
- ✅ GitHub variables configured

## Workflow Behavior

The workflow triggers on:
- Push to `main` branch (only when files in `src/**` change)
- Pull requests to any branch
- Manual trigger via GitHub UI (workflow_dispatch)

The workflow will:
1. Build your .NET application as a Docker container
2. Push the container to your Azure Container Registry
3. Deploy the container to your Azure App Service
4. Restart the App Service to ensure the new version is loaded

## Finding Your Resource Names

You can find your resource names by running:
```bash
# List your resource groups
az group list --output table

# List resources in your resource group
az resource list --resource-group {your-resource-group-name} --output table
```

Look for resources with types:
- `Microsoft.ContainerRegistry/registries` (for ACR name)
- `Microsoft.Web/sites` (for App Service name)

## Testing the Workflow

1. Create a Pull Request with your changes to test the workflow
2. The workflow will run automatically on the PR
3. Review the workflow results in the Actions tab
4. Once successful, merge the PR to deploy to the main branch

## Troubleshooting

If the workflow fails:
1. Check the Actions tab for detailed error logs
2. Verify all secrets and variables are configured correctly
3. Ensure your service principal has the correct permissions
4. Check that your Azure resources exist and are accessible
5. Review the application logs in Azure Portal if deployment succeeds but app doesn't load

## Application URL

After successful deployment, your application will be available at:
```
https://{your-app-service-name}.azurewebsites.net
```
