# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service.

## Prerequisites

Before the workflow can run successfully, you need to configure the following GitHub secrets and variables:

### Required GitHub Secrets

1. **AZURE_CREDENTIALS** - Azure service principal credentials for authentication

   To create this secret:

   ```bash
   # Create a service principal with contributor access to your resource group
   az ad sp create-for-rbac --name "github-actions-sp" \
     --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
     --json-auth
   ```

   Copy the entire JSON output and paste it as the value for the `AZURE_CREDENTIALS` secret.

### Required GitHub Variables

1. **AZURE_CONTAINER_REGISTRY_NAME** - The name of your Azure Container Registry (without .azurecr.io)
2. **AZURE_APP_SERVICE_NAME** - The name of your Azure App Service
3. **AZURE_RESOURCE_GROUP** - The name of your Azure Resource Group

### How to Configure Secrets and Variables

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Add the secret under the **Secrets** tab:
   - Click **New repository secret**
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the JSON output from the service principal creation command
4. Add the variables under the **Variables** tab:
   - Click **New repository variable** for each variable:
     - `AZURE_CONTAINER_REGISTRY_NAME`
     - `AZURE_APP_SERVICE_NAME`
     - `AZURE_RESOURCE_GROUP`

### Service Principal Permissions

The service principal needs the following permissions:
- **Contributor** role on the resource group (for App Service deployment)
- **AcrPush** role on the Azure Container Registry (for pushing container images)

To assign the ACR role:
```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

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
