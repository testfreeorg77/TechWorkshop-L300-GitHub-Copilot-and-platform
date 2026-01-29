using Azure;
using Azure.AI.ContentSafety;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ContentSafetyService
    {
        private readonly ContentSafetyClient _client;
        private readonly ILogger<ContentSafetyService> _logger;
        private const int SEVERITY_THRESHOLD = 2; // Block if severity >= 2

        public ContentSafetyService(IConfiguration configuration, ILogger<ContentSafetyService> logger)
        {
            var endpoint = configuration["AZURE_CONTENT_SAFETY_ENDPOINT"] 
                ?? configuration["AZURE_OPENAI_ENDPOINT"]?.Replace("openai", "contentsafety")
                ?? throw new InvalidOperationException("Content Safety endpoint not configured");
            
            _client = new ContentSafetyClient(new Uri(endpoint), new DefaultAzureCredential());
            _logger = logger;
        }

        public async Task<SafetyEvaluationResult> EvaluateTextAsync(string text)
        {
            try
            {
                var request = new AnalyzeTextOptions(text);
                Response<AnalyzeTextResult> response = await _client.AnalyzeTextAsync(request);

                var result = new SafetyEvaluationResult
                {
                    IsSafe = true
                };

                // Check each category
                foreach (var category in response.Value.CategoriesAnalysis)
                {
                    var categoryName = category.Category.ToString();
                    var severity = category.Severity;
                    
                    result.CategoryScores[categoryName] = severity;

                    // Log the evaluation
                    _logger.LogInformation(
                        "ContentSafety: Category={Category}, Severity={Severity}, Text={TextPreview}",
                        categoryName,
                        severity,
                        text.Length > 50 ? text.Substring(0, 50) + "..." : text
                    );

                    // Block if severity meets or exceeds threshold
                    if (severity >= SEVERITY_THRESHOLD)
                    {
                        result.IsSafe = false;
                        result.BlockedReason = $"Content blocked due to {categoryName} (severity {severity})";
                        
                        _logger.LogWarning(
                            "ContentSafety: BLOCKED - Category={Category}, Severity={Severity}, Reason={Reason}",
                            categoryName,
                            severity,
                            result.BlockedReason
                        );
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ContentSafety: Error evaluating text safety");
                // Fail open - allow the request but log the error
                return new SafetyEvaluationResult
                {
                    IsSafe = true,
                    BlockedReason = null
                };
            }
        }
    }
}
