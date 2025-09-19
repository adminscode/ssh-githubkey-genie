<#
.SYNOPSIS
  Sets up a new SSH key for GitHub on Windows:
  - Generates a fresh key
  - Starts ssh-agent and adds the key
  - Copies the public key to your clipboard
  - Tests the connection to GitHub

.NOTES
  It’s best to run this in an Administrator PowerShell session. That way,
  if OpenSSH isn’t installed or the ssh-agent service needs starting,
  the script can take care of it for you.
#>

Write-Host "== GitHub SSH Key Setup ==" -ForegroundColor Cyan

# Check if OpenSSH client tools are available, install if missing
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    Write-Host "OpenSSH client not found. Trying to install..." -ForegroundColor Yellow
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction Stop
        Write-Host "OpenSSH client installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Could not install OpenSSH client automatically. Please install it manually." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "OpenSSH client already available." -ForegroundColor Green
}

# Make sure ssh-agent service is running
$sshAgent = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($sshAgent) {
    if ($sshAgent.Status -ne "Running") {
        Write-Host "Starting ssh-agent service..." -ForegroundColor Yellow
        Set-Service -Name ssh-agent -StartupType Automatic
        Start-Service ssh-agent
        Write-Host "ssh-agent is now running." -ForegroundColor Green
    } else {
        Write-Host "ssh-agent is already running." -ForegroundColor Green
    }
} else {
    Write-Host "ssh-agent service not found. You may need to enable the OpenSSH Authentication Agent feature." -ForegroundColor Red
}

# Ask for GitHub email
$email = Read-Host "Enter your GitHub email address"

# Ask for passphrase (optional)
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

# Make sure .ssh folder exists
if (-not (Test-Path (Split-Path $keyPath))) {
    New-Item -ItemType Directory -Path (Split-Path $keyPath) -Force | Out-Null
}

# Backup old keys if they exist
if (Test-Path $keyPath) {
    Rename-Item $keyPath "$keyPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
}
if (Test-Path "$keyPath.pub") {
    Rename-Item "$keyPath.pub" "$keyPath.pub.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
}

# Generate a new SSH key
Write-Host "Generating SSH key..." -ForegroundColor Green
Invoke-Expression "ssh-keygen -t ed25519 -C `"$email`" -f `"$keyPath`" $passArg -q"

# Add the key to ssh-agent
try {
    ssh-add $keyPath | Out-Null
    Write-Host "Key added to ssh-agent." -ForegroundColor Green
} catch {
    Write-Host "Could not add key to ssh-agent. Run manually: ssh-add $keyPath" -ForegroundColor Yellow
}

# Copy the public key to the clipboard so it’s ready to paste in GitHub
Get-Content "$keyPath.pub" | Set-Clipboard
Write-Host "Your public key has been copied to the clipboard." -ForegroundColor Cyan
Write-Host "Go to GitHub → Settings → SSH and GPG keys → New SSH key, and paste it there."

# Show the key fingerprint
ssh-keygen -lf "$keyPath.pub"

# Test connection with GitHub
Write-Host "Testing GitHub connection..." -ForegroundColor Green
ssh -T git@github.com
