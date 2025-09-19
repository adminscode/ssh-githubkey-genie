# GitHub SSH Key Setup Scripts

This repository provides two scripts to automate the process of creating and configuring SSH keys for GitHub.

- **PowerShell Script**: `New-GitHubSSHKey.ps1` (Windows only)
- **Python Script**: `new_github_ssh_key.py` (Cross-platform: Windows, macOS, Linux)

---

## Features

### PowerShell Script
- Prompts for GitHub email address and optional passphrase.
- Creates a new Ed25519 SSH key.
- Backs up existing `id_ed25519` keys with a timestamp.
- Ensures `.ssh` directory exists.
- Enables and starts `ssh-agent`.
- Adds the new key to `ssh-agent`.
- Copies the public key to the clipboard.
- Shows the fingerprint.
- Tests the GitHub SSH connection.

### Python Script
- Cross-platform: runs on Windows, macOS, and Linux.
- Interactive prompts for:
  - GitHub email
  - Passphrase (optional)
  - GitHub token (optional, for automatic upload)
- Displays a **prerequisite checklist**.
- Installs missing requirements where possible:
  - OpenSSH tools (`ssh-keygen`, `ssh-agent`, `ssh-add`)
  - `xclip` (Linux only)
  - `requests` Python library
- Backs up old keys before generating new ones.
- Generates an Ed25519 SSH key.
- Starts `ssh-agent` and adds the key.
- Copies public key to clipboard.
- Shows fingerprint.
- Validates GitHub token before upload.
- Uploads public key directly to GitHub using the API.
- Tests the GitHub SSH connection.

---

## Requirements

### PowerShell Script
- Windows 10/11
- PowerShell 5.1 or later
- OpenSSH Client installed:
  ```powershell
  Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
  ```

### Python Script
- Python 3.6+
- Internet access
- Clipboard utilities:
  - Windows: `clip` (built-in)
  - macOS: `pbcopy` (built-in)
  - Linux: `xclip` (auto-installed if missing)
- GitHub personal access token (classic) with `admin:public_key` scope  
  (only required for automatic key upload)

---

## Usage

### PowerShell Version
1. Open **PowerShell as Administrator**.
2. Run:
   ```powershell
   .\New-GitHubSSHKey.ps1
   ```
3. Follow prompts for email and passphrase.
4. The public key will be copied to clipboard.  
   Paste it into GitHub → Settings → SSH and GPG keys.

### Python Version
1. Run the script:
   ```bash
   python new_github_ssh_key.py
   ```
2. Provide inputs when prompted:
   - GitHub email
   - Passphrase (optional)
   - GitHub token (optional, only for auto-upload)
3. The script will:
   - Check prerequisites and install missing ones
   - Generate a new SSH key
   - Add it to `ssh-agent`
   - Copy the public key to clipboard
   - Show the fingerprint
   - Upload the key to GitHub (if token provided)
   - Test the GitHub connection

---

## Testing the Setup

Both scripts run:

```bash
ssh -T git@github.com
```

Expected output if configured correctly:

```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## Notes
- Existing keys are automatically backed up with a timestamp.
- Ed25519 is the preferred key type. Use RSA only if required.
- The Python script is recommended for cross-platform environments and full automation.
