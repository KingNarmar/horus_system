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
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Read-AuthConfig {
  Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers
}

function Read-Template([string]$RelativePath) {
  $path = Join-Path $repositoryRoot $RelativePath
  if (-not (Test-Path $path)) {
    throw "Required email template not found: $RelativePath"
  }

  # Read directly through .NET so Windows PowerShell 5.1 does not attach
  # provider metadata that ConvertTo-Json can serialize as an object.
  return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Invoke-AuthPatch {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Payload,

    [Parameter(Mandatory = $true)]
    [string]$StepName
  )

  # Windows PowerShell 5.1 can otherwise send non-ASCII template content using
  # an ambiguous request encoding. Validate the generated JSON locally and send
  # explicit UTF-8 bytes because H.O.R.U.S templates contain Arabic text.
  $body = $Payload | ConvertTo-Json -Depth 5 -Compress
  $parsedBody = $body | ConvertFrom-Json

  # Fail before any Management API request if PowerShell serialized a string
  # payload value as an object or otherwise changed its content.
  foreach ($key in $Payload.Keys) {
    $expectedValue = $Payload[$key]
    if ($expectedValue -is [string]) {
      $actualValue = $parsedBody.$key
      if ($actualValue -isnot [string]) {
        throw "Auth PATCH property '$key' must serialize as a JSON string."
      }
      if ($actualValue -ne $expectedValue) {
        throw "Auth PATCH property '$key' changed during JSON serialization."
      }
    }
  }

  $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

  Write-Output "APPLY_STEP=$StepName"
  Write-Output "APPLY_STEP_BYTES=$($bodyBytes.Length)"

  Invoke-RestMethod `
    -Method Patch `
    -Uri $endpoint `
    -Headers $headers `
    -ContentType "application/json; charset=utf-8" `
    -Body $bodyBytes | Out-Null
}

function Assert-ConfigValue {
  param(
    [Parameter(Mandatory = $true)]
    $Config,

    [Parameter(Mandatory = $true)]
    [string]$PropertyName,

    [Parameter(Mandatory = $true)]
    $ExpectedValue,

    [Parameter(Mandatory = $true)]
    [string]$FailureMessage
  )

  if ($Config.$PropertyName -ne $ExpectedValue) {
    throw $FailureMessage
  }
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

$templateDefinitions = @(
  @{
    name = "CONFIRMATION"
    subjectProperty = "mailer_subjects_confirmation"
    subject = "H.O.R.U.S | Confirm your email"
    templateProperty = "mailer_templates_confirmation_content"
    templatePath = "supabase/templates/horus_confirmation.html"
  },
  @{
    name = "RECOVERY"
    subjectProperty = "mailer_subjects_recovery"
    subject = "H.O.R.U.S | Reset your password"
    templateProperty = "mailer_templates_recovery_content"
    templatePath = "supabase/templates/horus_recovery.html"
  },
  @{
    name = "EMAIL_CHANGE"
    subjectProperty = "mailer_subjects_email_change"
    subject = "H.O.R.U.S | Confirm your new email"
    templateProperty = "mailer_templates_email_change_content"
    templatePath = "supabase/templates/horus_email_change.html"
  },
  @{
    name = "INVITE"
    subjectProperty = "mailer_subjects_invite"
    subject = "H.O.R.U.S | You're invited"
    templateProperty = "mailer_templates_invite_content"
    templatePath = "supabase/templates/horus_invite.html"
  },
  @{
    name = "MAGIC_LINK"
    subjectProperty = "mailer_subjects_magic_link"
    subject = "H.O.R.U.S | Your secure sign-in link"
    templateProperty = "mailer_templates_magic_link_content"
    templatePath = "supabase/templates/horus_magic_link.html"
  },
  @{
    name = "REAUTHENTICATION"
    subjectProperty = "mailer_subjects_reauthentication"
    subject = "H.O.R.U.S | {{ .Token }} is your verification code"
    templateProperty = "mailer_templates_reauthentication_content"
    templatePath = "supabase/templates/horus_reauthentication.html"
  }
)

# Apply and verify templates first. Custom SMTP is deliberately enabled last so
# a template failure cannot leave Production on a new sender with incomplete
# H.O.R.U.S branding.
foreach ($definition in $templateDefinitions) {
  $templateContent = Read-Template $definition.templatePath
  $payload = @{}
  $payload[$definition.subjectProperty] = $definition.subject
  $payload[$definition.templateProperty] = $templateContent

  Invoke-AuthPatch -Payload $payload -StepName "TEMPLATE_$($definition.name)"

  $verifiedTemplate = Read-AuthConfig
  Assert-ConfigValue `
    -Config $verifiedTemplate `
    -PropertyName $definition.subjectProperty `
    -ExpectedValue $definition.subject `
    -FailureMessage "$($definition.name) email subject verification failed."
  Assert-ConfigValue `
    -Config $verifiedTemplate `
    -PropertyName $definition.templateProperty `
    -ExpectedValue $templateContent `
    -FailureMessage "$($definition.name) email template verification failed."

  Write-Output "TEMPLATE_$($definition.name)_VERIFIED=True"
}

$smtpPayload = @{
  external_email_enabled = $true
  mailer_autoconfirm = $false
  smtp_admin_email = $env:HORUS_SMTP_FROM
  smtp_host = $env:HORUS_SMTP_HOST
  smtp_port = $env:HORUS_SMTP_PORT
  smtp_user = $env:HORUS_SMTP_USER
  smtp_pass = $env:HORUS_SMTP_PASSWORD
  smtp_sender_name = $senderName
}

Invoke-AuthPatch -Payload $smtpPayload -StepName "CUSTOM_SMTP"

$verified = Read-AuthConfig

Assert-ConfigValue `
  -Config $verified `
  -PropertyName "smtp_host" `
  -ExpectedValue $env:HORUS_SMTP_HOST `
  -FailureMessage "SMTP host verification failed."
Assert-ConfigValue `
  -Config $verified `
  -PropertyName "smtp_port" `
  -ExpectedValue $env:HORUS_SMTP_PORT `
  -FailureMessage "SMTP port verification failed."
Assert-ConfigValue `
  -Config $verified `
  -PropertyName "smtp_user" `
  -ExpectedValue $env:HORUS_SMTP_USER `
  -FailureMessage "SMTP user verification failed."
Assert-ConfigValue `
  -Config $verified `
  -PropertyName "smtp_admin_email" `
  -ExpectedValue $env:HORUS_SMTP_FROM `
  -FailureMessage "SMTP From address verification failed."
Assert-ConfigValue `
  -Config $verified `
  -PropertyName "smtp_sender_name" `
  -ExpectedValue $senderName `
  -FailureMessage "SMTP sender name verification failed."

if ($verified.external_email_enabled -ne $true) {
  throw "External email verification failed."
}
if ($verified.mailer_autoconfirm -ne $false) {
  throw "Mailer autoconfirm verification failed."
}

Write-Output "CUSTOM_SMTP_VERIFIED=True"
Write-Output "AUTH_EMAIL_TEMPLATES_VERIFIED=True"
