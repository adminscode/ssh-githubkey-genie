<#
.SYNOPSIS
  Sets up a new SSH key for GitHub on Windows:
  - Generates a fresh key
  - Starts ssh-agent and adds the key
  - Copies the public key to your clipboard
  - Optionally uploads the key to GitHub using the API
  - Tests the connection to GitHub

.NOTES
  Run this in an Administrator PowerShell session so the script can install OpenSSH
  or start the ssh-agent service if needed.
#>

Write-Host "== GitHub SSH Key Setup ==" -ForegroundColor Cyan

# Helper: Check if a command exists
function Test-CommandExists {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Track results for summary
$results = @{
    "OpenSSH Client"   = "Skipped"
    "ssh-agent"        = "Skipped"
    "SSH key created"  = "Skipped"
    "Key added to agent" = "Skipped"
    "Key copied to clipboard" = "Skipped"
    "GitHub token"     = "Skipped"
    "Key uploaded to GitHub" = "Skipped"
    "GitHub connection test" = "Skipped"
}

# Prerequisite checklist
Write-Host "`n== Prerequisite Checklist ==" -ForegroundColor Yellow

if (Test-CommandExists "ssh-keygen") {
    Write-Host "ssh-keygen available" -ForegroundColor Green
} else {
    Write-Host "ssh-keygen missing" -ForegroundColor Red
}
if (Test-CommandExists "ssh-agent") {
    Write-Host "ssh-agent available" -ForegroundColor Green
} else {
    Write-Host "ssh-agent missing" -ForegroundColor Red
}
if (Test-CommandExists "ssh-add") {
    Write-Host "ssh-add available" -ForegroundColor Green
} else {
    Write-Host "ssh-add missing" -ForegroundColor Red
}
if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Write-Host "Clipboard support available" -ForegroundColor Green
} else {
    Write-Host "Clipboard support missing" -ForegroundColor Red
}
try {
    $null = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -TimeoutSec 5
    Write-Host "Internet connectivity looks good" -ForegroundColor Green
} catch {
    Write-Host "Could not confirm internet connectivity" -ForegroundColor Red
}

Write-Host "`nContinuing with setup...`n"

# Install OpenSSH if missing
if (-not (Test-CommandExists "ssh-keygen")) {
    Write-Host "OpenSSH client not found. Attempting to install..." -ForegroundColor Yellow
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction Stop
        Write-Host "OpenSSH client installed successfully." -ForegroundColor Green
        $results["OpenSSH Client"] = "Success"
    } catch {
        Write-Host "Could not install OpenSSH client automatically." -ForegroundColor Red
        $results["OpenSSH Client"] = "Failed"
        exit 1
    }
} else {
    $results["OpenSSH Client"] = "Success"
}

# Make sure ssh-agent service is running
$sshAgent = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($sshAgent) {
    if ($sshAgent.Status -ne "Running") {
        Write-Host "Starting ssh-agent service..." -ForegroundColor Yellow
        Set-Service -Name ssh-agent -StartupType Automatic
        Start-Service ssh-agent
        Write-Host "ssh-agent is now running." -ForegroundColor Green
    }
    $results["ssh-agent"] = "Success"
} else {
    Write-Host "ssh-agent service not found." -ForegroundColor Red
    $results["ssh-agent"] = "Failed"
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
if (Test-Path $keyPath) {
    $results["SSH key created"] = "Success"
} else {
    $results["SSH key created"] = "Failed"
}

# Add the key to ssh-agent
try {
    ssh-add $keyPath | Out-Null
    Write-Host "Key added to ssh-agent." -ForegroundColor Green
    $results["Key added to agent"] = "Success"
} catch {
    Write-Host "Could not add key to ssh-agent." -ForegroundColor Yellow
    $results["Key added to agent"] = "Failed"
}

# Copy the public key to the clipboard
try {
    Get-Content "$keyPath.pub" | Set-Clipboard
    Write-Host "Your public key has been copied to the clipboard." -ForegroundColor Cyan
    $results["Key copied to clipboard"] = "Success"
} catch {
    Write-Host "Could not copy public key to clipboard." -ForegroundColor Yellow
    $results["Key copied to clipboard"] = "Failed"
}

# Show the key fingerprint
ssh-keygen -lf "$keyPath.pub"

# Ask if user wants to upload key to GitHub automatically
$uploadChoice = Read-Host "Do you want to upload the key to GitHub automatically? (y/n)"
if ($uploadChoice -eq "y") {
    $token = Read-Host "Enter your GitHub Personal Access Token (with admin:public_key scope)" -AsSecureString
    $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
    )

    # Validate token
    try {
        $userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" `
            -Headers @{ Authorization = "token $plainToken" }
        Write-Host "GitHub token validated. Authenticated as $($userResponse.login)." -ForegroundColor Green
        $results["GitHub token"] = "Valid"
    } catch {
        Write-Host "Invalid GitHub token or unable to reach GitHub." -ForegroundColor Red
        $results["GitHub token"] = "Invalid"
        $plainToken = $null
    }

    if ($plainToken) {
        $pubKey = Get-Content "$keyPath.pub" -Raw
        $body = @{
            title = "SSH Key $env:COMPUTERNAME $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            key   = $pubKey
        } | ConvertTo-Json

        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/user/keys" `
                -Method Post `
                -Headers @{ Authorization = "token $plainToken" } `
                -Body $body

            if ($response.id) {
                Write-Host "Public key uploaded successfully to GitHub." -ForegroundColor Green
                $results["Key uploaded to GitHub"] = "Success"
            } else {
                Write-Host "Upload failed." -ForegroundColor Red
                $results["Key uploaded to GitHub"] = "Failed"
            }
        } catch {
            Write-Host "Error uploading key." -ForegroundColor Red
            $results["Key uploaded to GitHub"] = "Failed"
        }
    }
}

# Test connection with GitHub
Write-Host "Testing GitHub connection..." -ForegroundColor Green
try {
    ssh -T git@github.com
    $results["GitHub connection test"] = "Attempted"
} catch {
    $results["GitHub connection test"] = "Failed"
}

# Final summary
Write-Host "`n== Setup Summary ==" -ForegroundColor Yellow
foreach ($step in $results.Keys) {
    Write-Host "$step : $($results[$step])"
}
