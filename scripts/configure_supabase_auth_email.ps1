param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,

  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,

  [switch]$Apply
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  throw "SUPABASE_ACCESS_TOKEN is required."
}

$headers = @{
  Authorization = "Bearer $AccessToken"
}

$endpoint = "https://api.supabase.com/v1/projects/$ProjectRef/config/auth"

function Read-AuthConfig {
  Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Read-Template([string]$RelativePath) {
  $path = Join-Path $repositoryRoot $RelativePath
  if (-not (Test-Path $path)) {
    throw "Required email template not found: $RelativePath"
  }
  return Get-Content -Raw -Path $path
}

$current = Read-AuthConfig

Write-Output "AUTH_EMAIL_PROJECT_REF=$ProjectRef"
Write-Output "CURRENT_SMTP_HOST=$($current.smtp_host)"
Write-Output "CURRENT_SMTP_SENDER_NAME=$($current.smtp_sender_name)"
Write-Output "CURRENT_SMTP_FROM=$($current.smtp_admin_email)"
Write-Output "CURRENT_CONFIRMATION_SUBJECT=$($current.mailer_subjects_confirmation)"

if (-not $Apply) {
  Write-Output "MODE=VERIFY_ONLY"
  exit 0
}

$requiredEnvironmentValues = @{
  HORUS_SMTP_HOST = $env:HORUS_SMTP_HOST
  HORUS_SMTP_PORT = $env:HORUS_SMTP_PORT
  HORUS_SMTP_USER = $env:HORUS_SMTP_USER
  HORUS_SMTP_PASSWORD = $env:HORUS_SMTP_PASSWORD
  HORUS_SMTP_FROM = $env:HORUS_SMTP_FROM
}

foreach ($entry in $requiredEnvironmentValues.GetEnumerator()) {
  if ([string]::IsNullOrWhiteSpace($entry.Value)) {
    throw "$($entry.Key) is required when -Apply is used."
  }
}

$senderName = if ([string]::IsNullOrWhiteSpace($env:HORUS_SMTP_SENDER_NAME)) {
  "H.O.R.U.S System"
} else {
  $env:HORUS_SMTP_SENDER_NAME
}

$payload = @{
  external_email_enabled = $true
  mailer_autoconfirm = $false
  smtp_admin_email = $env:HORUS_SMTP_FROM
  smtp_host = $env:HORUS_SMTP_HOST
  smtp_port = $env:HORUS_SMTP_PORT
  smtp_user = $env:HORUS_SMTP_USER
  smtp_pass = $env:HORUS_SMTP_PASSWORD
  smtp_sender_name = $senderName

  mailer_subjects_confirmation = "H.O.R.U.S | Confirm your email"
  mailer_templates_confirmation_content = Read-Template "supabase/templates/horus_confirmation.html"

  mailer_subjects_recovery = "H.O.R.U.S | Reset your password"
  mailer_templates_recovery_content = Read-Template "supabase/templates/horus_recovery.html"

  mailer_subjects_email_change = "H.O.R.U.S | Confirm your new email"
  mailer_templates_email_change_content = Read-Template "supabase/templates/horus_email_change.html"

  mailer_subjects_invite = "H.O.R.U.S | You're invited"
  mailer_templates_invite_content = Read-Template "supabase/templates/horus_invite.html"

  mailer_subjects_magic_link = "H.O.R.U.S | Your secure sign-in link"
  mailer_templates_magic_link_content = Read-Template "supabase/templates/horus_magic_link.html"

  mailer_subjects_reauthentication = "H.O.R.U.S | {{ .Token }} is your verification code"
  mailer_templates_reauthentication_content = Read-Template "supabase/templates/horus_reauthentication.html"
}

# Windows PowerShell 5.1 can otherwise send non-ASCII template content using
# an ambiguous request encoding. Build, validate, and send explicit UTF-8 JSON
# because the H.O.R.U.S templates contain Arabic text.
$body = $payload | ConvertTo-Json -Depth 5 -Compress
$null = $body | ConvertFrom-Json
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

Invoke-RestMethod `
  -Method Patch `
  -Uri $endpoint `
  -Headers $headers `
  -ContentType "application/json; charset=utf-8" `
  -Body $bodyBytes | Out-Null

$verified = Read-AuthConfig

if ($verified.smtp_host -ne $env:HORUS_SMTP_HOST) {
  throw "SMTP host verification failed."
}
if ($verified.smtp_admin_email -ne $env:HORUS_SMTP_FROM) {
  throw "SMTP From address verification failed."
}
if ($verified.smtp_sender_name -ne $senderName) {
  throw "SMTP sender name verification failed."
}
if ($verified.mailer_subjects_confirmation -ne $payload.mailer_subjects_confirmation) {
  throw "Confirmation template subject verification failed."
}
if ($verified.mailer_subjects_recovery -ne $payload.mailer_subjects_recovery) {
  throw "Recovery template subject verification failed."
}

Write-Output "CUSTOM_SMTP_VERIFIED=True"
Write-Output "AUTH_EMAIL_TEMPLATES_VERIFIED=True"
