namespace ZavaStorefront.Models
{
    public class SafetyEvaluationResult
    {
        public bool IsSafe { get; set; }
        public string? BlockedReason { get; set; }
        public Dictionary<string, int> CategoryScores { get; set; } = new();
    }
}
