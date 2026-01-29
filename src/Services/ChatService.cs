using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly string _endpoint;
        private readonly string _deploymentName;
        private readonly ILogger<ChatService> _logger;
        private readonly List<ChatMessage> _conversationHistory;
        private readonly ContentSafetyService _contentSafetyService;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger, ContentSafetyService contentSafetyService)
        {
            _endpoint = configuration["AZURE_OPENAI_ENDPOINT"] 
                ?? throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT not configured");
            _deploymentName = "gpt-4o"; // As configured in main.bicep
            _logger = logger;
            _conversationHistory = new List<ChatMessage>();
            _contentSafetyService = contentSafetyService;
        }

        public async Task<ChatResponse> SendMessageAsync(string userMessage)
        {
            try
            {
                // Check content safety first
                var safetyResult = await _contentSafetyService.EvaluateTextAsync(userMessage);
                
                if (!safetyResult.IsSafe)
                {
                    _logger.LogWarning("Message blocked by content safety: {Reason}", safetyResult.BlockedReason);
                    return new ChatResponse
                    {
                        Response = $"⚠️ Your message was blocked by our content safety system: {safetyResult.BlockedReason}. Please rephrase your question.",
                        Success = false,
                        Error = safetyResult.BlockedReason
                    };
                }

                // Add user message to history
                _conversationHistory.Add(new ChatMessage
                {
                    Role = "user",
                    Content = userMessage
                });

                // Use DefaultAzureCredential for authentication
                // This works with Managed Identity in Azure and local dev credentials
                var client = new OpenAIClient(new Uri(_endpoint), new DefaultAzureCredential());
                
                var chatCompletionsOptions = new ChatCompletionsOptions()
                {
                    DeploymentName = _deploymentName,
                    Messages =
                    {
                        new ChatRequestSystemMessage("You are a helpful assistant for Zava Storefront. Help customers with product information and pricing questions. Be friendly and concise."),
                    }
                };

                // Add conversation history
                foreach (var msg in _conversationHistory)
                {
                    if (msg.Role == "user")
                    {
                        chatCompletionsOptions.Messages.Add(new ChatRequestUserMessage(msg.Content));
                    }
                    else if (msg.Role == "assistant")
                    {
                        chatCompletionsOptions.Messages.Add(new ChatRequestAssistantMessage(msg.Content));
                    }
                }

                Response<ChatCompletions> response = await client.GetChatCompletionsAsync(chatCompletionsOptions);
                ChatResponseMessage responseMessage = response.Value.Choices[0].Message;

                // Add assistant response to history
                _conversationHistory.Add(new ChatMessage
                {
                    Role = "assistant",
                    Content = responseMessage.Content
                });

                return new ChatResponse
                {
                    Response = responseMessage.Content,
                    Success = true
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message to chat service");
                return new ChatResponse
                {
                    Response = string.Empty,
                    Success = false,
                    Error = $"Failed to get response: {ex.Message}"
                };
            }
        }

        public List<ChatMessage> GetConversationHistory()
        {
            return _conversationHistory.ToList();
        }

        public void ClearHistory()
        {
            _conversationHistory.Clear();
        }
    }
}
