# Chatbot Feature Setup Instructions

## Overview
This chatbot feature integrates with Azure OpenAI/Microsoft Foundry to provide an interactive chat experience for Zava Storefront customers.

## Configuration

The chatbot requires the Azure OpenAI endpoint to be configured. There are three ways to set this up:

### Option 1: Environment Variable (Recommended for Production)
Set the following environment variable:
```bash
export AZURE_OPENAI_ENDPOINT="https://oai3q5rgs3v7fkls.openai.azure.com/"
```

For Windows PowerShell:
```powershell
$env:AZURE_OPENAI_ENDPOINT="https://oai3q5rgs3v7fkls.openai.azure.com/"
```

### Option 2: User Secrets (Recommended for Local Development)
```bash
cd src
dotnet user-secrets set "AZURE_OPENAI_ENDPOINT" "https://oai3q5rgs3v7fkls.openai.azure.com/"
```

### Option 3: Update appsettings.json (Not Recommended - Secrets Risk)
Edit `src/appsettings.json` and add:
```json
{
  "AZURE_OPENAI_ENDPOINT": "https://oai3q5rgs3v7fkls.openai.azure.com/"
}
```

**Note:** Do not commit secrets to the repository!

## Azure Configuration

The application uses:
- **Endpoint**: `https://oai3q5rgs3v7fkls.openai.azure.com/`
- **Deployment Name**: `gpt-4o` (as configured in infrastructure)
- **Authentication**: Azure Managed Identity (when deployed) or Azure Key Credential

### For Local Development
The service uses a dummy key credential for local testing. In production, Azure Managed Identity handles authentication automatically.

## Features

- **Real-time Chat**: Interactive conversation with the AI assistant
- **Conversation History**: Maintains context throughout the chat session
- **Error Handling**: Graceful error messages for API failures
- **Responsive UI**: Mobile-friendly chat interface
- **Clear History**: Option to reset the conversation

## Testing

1. Configure the endpoint using one of the methods above
2. Build and run the application:
   ```bash
   cd src
   dotnet build
   dotnet run
   ```
3. Navigate to the Chat page from the navigation menu
4. Start chatting!

## Deployment

When deploying to Azure App Service:
1. The `AZURE_OPENAI_ENDPOINT` environment variable is set via the App Service configuration (already configured in infra)
2. Azure Managed Identity provides automatic authentication
3. No additional configuration needed!

## Troubleshooting

### "AZURE_OPENAI_ENDPOINT not configured" Error
- Ensure the environment variable or user secret is set
- Restart the application after setting the configuration

### Connection Errors
- Verify the endpoint URL is correct
- Check that the Azure OpenAI resource is deployed and accessible
- Ensure the `gpt-4o` deployment exists in the Azure OpenAI resource

### Authentication Errors
- In production, ensure the App Service has Managed Identity enabled
- Verify the Managed Identity has appropriate permissions to the Azure OpenAI resource

## Files Created

- `Models/ChatMessage.cs` - Chat message models
- `Services/ChatService.cs` - Chat service implementation
- `Controllers/ChatController.cs` - Chat controller
- `Views/Chat/Index.cshtml` - Chat UI
- Updated `Program.cs` - Registered ChatService
- Updated `_Layout.cshtml` - Added Chat navigation link
- Updated `ZavaStorefront.csproj` - Added Azure.AI.OpenAI package

## Related Issue

Closes #4
