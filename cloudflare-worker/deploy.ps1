# One-shot setup for the question assistant backend.
# Run in PowerShell:  .\deploy.ps1
# Needs: Node.js, a Cloudflare account, an Anthropic API key, a Resend API key.
# Keys are typed here, hidden, and sent straight to Cloudflare. They are not saved to any file.

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host "Node.js is required. Install it from https://nodejs.org and run this again." -ForegroundColor Red; exit 1
}

function Read-Secret([string]$label) {
  $s = Read-Host $label -AsSecureString
  $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

Write-Host "`n1/4  Log in to Cloudflare (a browser window opens)" -ForegroundColor Cyan
npx wrangler login
if ($LASTEXITCODE -ne 0) { Write-Host "Cloudflare login failed." -ForegroundColor Red; exit 1 }

Write-Host "`n2/4  Deploying the Worker" -ForegroundColor Cyan
$out = (npx wrangler deploy 2>&1 | Out-String)
Write-Host $out
$m = [regex]::Match($out, 'https://[A-Za-z0-9.-]+\.workers\.dev')
if (-not $m.Success) { Write-Host "Could not find the Worker URL in the deploy output." -ForegroundColor Red; exit 1 }
$url = $m.Value

Write-Host "`n3/4  Add your keys (typing is hidden)" -ForegroundColor Cyan
$anthropic = Read-Secret "Anthropic API key"
$anthropic | npx wrangler secret put ANTHROPIC_API_KEY
$resend = Read-Secret "Resend API key"
$resend | npx wrangler secret put RESEND_API_KEY
$anthropic = $null; $resend = $null

Write-Host "`n4/4  Pointing the website at the Worker" -ForegroundColor Cyan
$page = Join-Path $PSScriptRoot "..\index.html"
$html = [IO.File]::ReadAllText($page)
$html = [regex]::Replace($html, 'const CHAT_API_URL = "[^"]*";', "const CHAT_API_URL = `"$url`";")
[IO.File]::WriteAllText($page, $html, (New-Object Text.UTF8Encoding($false)))

Write-Host "`nDone. Worker URL: $url" -ForegroundColor Green
Write-Host "index.html is updated. Tell Claude 'deployed' and it will check the Worker and push the change live."
