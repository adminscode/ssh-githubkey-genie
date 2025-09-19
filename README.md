# ssh-githubkey-genie

A cross-platform tool that automates GitHub SSH key setup.  
Includes both a **PowerShell script (Windows)** and a **Python script (Windows, macOS, Linux)**.  

---

## Features

### PowerShell Script (`New-GitHubSSHKey.ps1`)

- Interactive prompts for GitHub email and optional passphrase.
- Prerequisite checklist:
  - Checks for OpenSSH tools (ssh-keygen, ssh-agent, ssh-add).
  - Ensures clipboard support.
  - Confirms internet connectivity.
- Installs OpenSSH client if missing (Windows only).
- Starts and configures ssh-agent.
- Generates an Ed25519 SSH key (preferred by GitHub).
- Backs up old keys automatically with timestamps.
- Adds the key to ssh-agent.
- Copies the public key to the clipboard.
- Shows the key fingerprint.
- Optionally validates and uploads the key directly to GitHub using a personal access token.
- Tests the GitHub SSH connection.
- Prints a final summary of all steps (success/failure).

### Python Script (`new_github_ssh_key.py`)

- Cross-platform: works on Windows, macOS, and Linux.
- Interactive prompts for:
  - GitHub email
  - Passphrase (optional)
  - GitHub token (optional, for automatic upload)
- Displays a prerequisite checklist.
- Installs missing requirements where possible:
  - OpenSSH tools (ssh-keygen, ssh-agent, ssh-add)
  - xclip (Linux only, for clipboard support)
  - requests Python library
- Backs up old keys before generating new ones.
- Generates an Ed25519 SSH key.
- Starts ssh-agent and adds the key.
- Copies public key to clipboard.
- Shows fingerprint.
- Validates GitHub token before upload.
- Uploads public key directly to GitHub using the API.
- Tests the GitHub SSH connection.

---

## Requirements

### PowerShell Script (Requirements)

- Windows 10/11
- PowerShell 5.1 or later
- Internet access
- OpenSSH Client (auto-installed if missing)

### Python Script (Requirements)

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

### PowerShell Script

1. Open **PowerShell as Administrator**.
2. Run:

   ```powershell
   .\New-GitHubSSHKey.ps1
   ```

3. Provide your GitHub email and optional passphrase.
4. The script will:
   - Check prerequisites
   - Generate and back up keys
   - Add the new key to ssh-agent
   - Copy the public key to the clipboard
   - Optionally validate and upload the key to GitHub
   - Test the GitHub SSH connection
   - Show a final setup summary

### Python Script

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
   - Add it to ssh-agent
   - Copy the public key to clipboard
   - Show the fingerprint
   - Upload the key to GitHub (if token provided)
   - Test the GitHub connection

---

## Testing the Setup

Both scripts automatically run:

```bash
ssh -T git@github.com
```

Expected output if configured correctly:

```text
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## Notes

- Existing keys are automatically backed up with a timestamp.
- Ed25519 is the preferred key type. Use RSA only if required.
- The PowerShell script is designed for Windows and includes automatic OpenSSH installation.
- The Python script is fully cross-platform and handles prerequisites on Windows, macOS, and Linux.
