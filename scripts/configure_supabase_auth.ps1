param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("development", "production")]
  [string]$Environment,

  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,

  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,

  [switch]$Apply
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  throw "SUPABASE_ACCESS_TOKEN is required."
}

$configByEnvironment = @{
  development = @{
    site_url = "http://localhost:5173/horus/auth/confirmed"
    uri_allow_list = @(
      "http://localhost:5173/horus/auth/confirmed",
      "http://localhost:5173/horus/confirm",
      "http://localhost:5173/horus/confirm-email",
      "http://localhost:5173/horus/reset-password"
    )
  }
  production = @{
    site_url = "https://kingnarmar.com/horus/auth/confirmed"
    uri_allow_list = @(
      "https://kingnarmar.com/horus/auth/confirmed",
      "https://kingnarmar.com/horus/confirm",
      "https://kingnarmar.com/horus/confirm-email",
      "https://kingnarmar.com/horus/reset-password"
    )
  }
}

$expected = $configByEnvironment[$Environment]

if ($Environment -eq "production") {
  if ($expected.site_url -match "localhost|127\.0\.0\.1|\[::1\]") {
    throw "Production Site URL must never target a loopback host."
  }

  foreach ($url in $expected.uri_allow_list) {
    if (-not $url.StartsWith("https://")) {
      throw "Every Production Auth redirect URL must use HTTPS."
    }
  }
}

$headers = @{
  Authorization = "Bearer $AccessToken"
  "Content-Type" = "application/json"
}

$endpoint = "https://api.supabase.com/v1/projects/$ProjectRef/config/auth"

function Read-AuthConfig {
  Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers
}

$current = Read-AuthConfig

Write-Output "AUTH_CONFIG_ENVIRONMENT=$Environment"
Write-Output "AUTH_CONFIG_PROJECT_REF=$ProjectRef"
Write-Output "CURRENT_SITE_URL=$($current.site_url)"
Write-Output "EXPECTED_SITE_URL=$($expected.site_url)"

if (-not $Apply) {
  Write-Output "MODE=VERIFY_ONLY"
  exit 0
}

$body = @{
  site_url = $expected.site_url
  uri_allow_list = ($expected.uri_allow_list -join ",")
} | ConvertTo-Json -Compress

Invoke-RestMethod -Method Patch -Uri $endpoint -Headers $headers -Body $body | Out-Null

$verified = Read-AuthConfig
$actualAllowList = @(
  ($verified.uri_allow_list -split ",") |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ }
)

$missing = @(
  $expected.uri_allow_list |
    Where-Object { $_ -notin $actualAllowList }
)

if ($verified.site_url -ne $expected.site_url) {
  throw "Auth Site URL verification failed."
}

if ($missing.Count -gt 0) {
  throw "Auth redirect allow-list verification failed. Missing: $($missing -join ', ')"
}

Write-Output "AUTH_SITE_URL_VERIFIED=True"
Write-Output "AUTH_REDIRECT_ALLOW_LIST_VERIFIED=True"
