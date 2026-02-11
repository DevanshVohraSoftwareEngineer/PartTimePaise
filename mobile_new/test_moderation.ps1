param (
    [Parameter(Mandatory = $true)]
    [string]$Text
)

# Load API Key from .env
$envFile = ".env"
if (Test-Path $envFile) {
    $apiKeyLine = Get-Content $envFile | Where-Object { $_ -match "GEMINI_API_KEY=" }
    if ($apiKeyLine) {
        $API_KEY = $apiKeyLine.Split("=")[1].Trim()
    }
}

if (-not $API_KEY) {
    Write-Host "Error: GEMINI_API_KEY not found in .env" -ForegroundColor Red
    exit
}

$baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY"

$prompt = @"
TASK: STRICT CONTENT MODERATION & QUALITY CHECK
Analyze the following text for:
1. SAFETY: Check for sexually abusive, explicit, illegal, violent, or hate speech content.
2. QUALITY: Check if the text is gibberish, random key-mashing (e.g. "asdfg"), or nonsensical. It must be a GENUINE task request.

STRICT ZERO TOLERANCE POLICY FOR:
- Sexual violence, harassment, or strictly adult content.
- Illegal acts (drugs, weapons, scams, hacking).
- Hate speech or severe profanity.
- RANDOM/GIBBERISH text or meaningless strings (e.g. "dhjdjd", "testing 123" without context).

TEXT TO ANALYZE (can be in Hindi, English, Hinglish, etc.):
"$Text"

JSON RESPONSE SCHEMA:
{
  "is_safe": boolean, 
  "reason": "Short explanation for user if blocked", 
  "flagged_content": "The specific words or phrases that triggered the block, or 'Gibberish'"
}
"@

$body = @{
    contents         = @(
        @{
            parts = @(
                @{
                    text = $prompt
                }
            )
        }
    )
    generationConfig = @{
        responseMimeType = "application/json"
        temperature      = 0.0
    }
} | ConvertTo-Json -Depth 10

Write-Host "Analyzing: '$Text'..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $body -ContentType "application/json"
    $resultText = $response.candidates[0].content.parts[0].text
    $result = $resultText | ConvertFrom-Json
    
    if ($result.is_safe) {
        Write-Host "SAFE: No prohibited content detected." -ForegroundColor Green
    }
    else {
        Write-Host "BLOCKED: Content flagged." -ForegroundColor Red
        Write-Host "Reason: $($result.reason)"
        Write-Host "Flagged: $($result.flagged_content)"
    }
}
catch {
    Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Red
}
