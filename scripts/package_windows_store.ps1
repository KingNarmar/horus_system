$ErrorActionPreference = "Stop"

$buildFolder = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Release"
$imagesFolder = Join-Path $buildFolder "Images"
$msixPath = Join-Path $buildFolder "horus-system-store.msix"

function Invoke-DartMsix {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & dart @Arguments

  if ($LASTEXITCODE -ne 0) {
    throw "dart $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

function Convert-BadgeLogoToWhiteMask {
  param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileInfo]$File
  )

  Add-Type -AssemblyName System.Drawing

  $bitmap = [System.Drawing.Bitmap]::new($File.FullName)

  try {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
      for ($x = 0; $x -lt $bitmap.Width; $x++) {
        $pixel = $bitmap.GetPixel($x, $y)

        if ($pixel.A -eq 0) {
          continue
        }

        $whitePixel = [System.Drawing.Color]::FromArgb(
          $pixel.A,
          255,
          255,
          255
        )
        $bitmap.SetPixel($x, $y, $whitePixel)
      }
    }

    $temporaryPath = "$($File.FullName).tmp.png"
    $bitmap.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $bitmap.Dispose()
  }

  Move-Item -Path $temporaryPath -Destination $File.FullName -Force

  $verificationBitmap = [System.Drawing.Bitmap]::new($File.FullName)

  try {
    for ($y = 0; $y -lt $verificationBitmap.Height; $y++) {
      for ($x = 0; $x -lt $verificationBitmap.Width; $x++) {
        $pixel = $verificationBitmap.GetPixel($x, $y)

        if (
          $pixel.A -ne 0 -and
          ($pixel.R -ne 255 -or $pixel.G -ne 255 -or $pixel.B -ne 255)
        ) {
          throw "Badge logo '$($File.Name)' contains a non-white visible pixel at ($x, $y)."
        }
      }
    }
  }
  finally {
    $verificationBitmap.Dispose()
  }
}

Invoke-DartMsix -Arguments @("run", "msix:build", "--build-windows", "false")

if (-not (Test-Path $imagesFolder)) {
  throw "MSIX Images folder was not generated at '$imagesFolder'."
}

$badgeFiles = @(
  Get-ChildItem -Path $imagesFolder -Filter "BadgeLogo.scale-*.png" -File |
    Sort-Object Name
)

$expectedBadgeFiles = @(
  "BadgeLogo.scale-100.png",
  "BadgeLogo.scale-125.png",
  "BadgeLogo.scale-150.png",
  "BadgeLogo.scale-200.png",
  "BadgeLogo.scale-400.png"
)

$actualBadgeFiles = @($badgeFiles.Name)

if (
  $actualBadgeFiles.Count -ne $expectedBadgeFiles.Count -or
  (Compare-Object $expectedBadgeFiles $actualBadgeFiles)
) {
  throw "Unexpected BadgeLogo asset set. Expected: $($expectedBadgeFiles -join ', '). Actual: $($actualBadgeFiles -join ', ')."
}

foreach ($badgeFile in $badgeFiles) {
  Convert-BadgeLogoToWhiteMask -File $badgeFile
}

Write-Output "WINDOWS_STORE_BADGE_ASSETS=COMPLIANT"
Write-Output "WINDOWS_STORE_BADGE_COUNT=$($badgeFiles.Count)"

Invoke-DartMsix -Arguments @("run", "msix:pack")

if (-not (Test-Path $msixPath)) {
  throw "Expected Microsoft Store MSIX package was not generated at '$msixPath'."
}

Write-Output "WINDOWS_STORE_MSIX=$msixPath"
