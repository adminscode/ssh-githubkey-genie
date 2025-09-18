<#
.SYNOPSIS
  Create an SSH key for GitHub, add it to ssh-agent, copy pubkey to clipboard, and test.

.NOTES
  Run in Administrator PowerShell for capability install and service start.
#>

Write-Host "== GitHub SSH Key Setup ==" -ForegroundColor Cyan

# Prompt for email
$email = Read-Host "Enter your GitHub email address"

# Prompt for optional passphrase
$passphrase = Read-Host "Enter a passphrase (or leave blank for none)" -AsSecureString
if ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passphrase)) -eq "") {
    $passArg = '-N ""'
} else {
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passphrase))
    $passArg = "-N `"$plain`""
}

$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"

# Ensure .ssh folder exists
if (-not (Test-Path (Split-Path $keyPath))) {
    New-Item -ItemType Directory -Path (Split-Path $keyPath) -Force | Out-Null
}

# Backup existing key if present
if (Test-Path $keyPath) {
    Rename-Item $keyPath "$keyPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
}
if (Test-Path "$keyPath.pub") {
    Rename-Item "$keyPath.pub" "$keyPath.pub.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
}

# Generate key
Write-Host "Generating SSH key..." -ForegroundColor Green
Invoke-Expression "ssh-keygen -t ed25519 -C `"$email`" -f `"$keyPath`" $passArg -q"

# Start ssh-agent if possible
try {
    Set-Service -Name ssh-agent -StartupType Automatic -ErrorAction Stop
    Start-Service ssh-agent -ErrorAction Stop
} catch {
    Write-Host "Could not auto-start ssh-agent, you may need to start it manually." -ForegroundColor Yellow
}

# Add key
try {
    ssh-add $keyPath | Out-Null
    Write-Host "Key added to ssh-agent." -ForegroundColor Green
} catch {
    Write-Host "Failed to add key. Run: ssh-add $keyPath" -ForegroundColor Yellow
}

# Copy pubkey to clipboard
Get-Content "$keyPath.pub" | clip
Write-Host "Your public key has been copied to the clipboard." -ForegroundColor Cyan
Write-Host "Paste it into GitHub -> Settings -> SSH and GPG keys -> New SSH key."

# Show fingerprint
ssh-keygen -lf "$keyPath.pub"

# Test connection
Write-Host "Testing GitHub connection..." -ForegroundColor Green
ssh -T git@github.com
