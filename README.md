# New-GitHubSSHKey.ps1

## Overview
`New-GitHubSSHKey.ps1` is a PowerShell automation script that creates and configures a new SSH key for GitHub. It removes the manual steps of generating keys, starting the SSH agent, adding keys, and copying the public key to your clipboard.

With this script, you only need to run it once, answer a couple of prompts, and you’ll be ready to add the new SSH key to your GitHub account.

---

## Features
- Prompts for your **GitHub email address** (used as the key comment).
- Prompts for an **optional passphrase** (adds extra security).
- Creates an **Ed25519 SSH key** (recommended by GitHub).
- Backs up any existing key (`id_ed25519` and `.pub`) before generating a new one.
- Ensures the `.ssh` folder exists.
- Attempts to **enable and start the ssh-agent** service.
- Adds the new key to `ssh-agent`.
- Copies the **public key** to the clipboard.
- Displays the key fingerprint.
- Tests the GitHub SSH connection.

---

## Requirements
- **Windows 10/11** with the **OpenSSH Client** installed.  
  (Most recent Windows installs include it by default. If not, install with:)  
  ```powershell
  Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
  ```
- PowerShell 5.1 or later.
- Internet access (to test the connection to GitHub).

---

## Usage
1. Save the script as `New-GitHubSSHKey.ps1`.
2. Open **PowerShell as Administrator** (recommended for starting services).
3. Run:
   ```powershell
   .\New-GitHubSSHKey.ps1
   ```
4. Enter your GitHub email address when prompted.
5. Enter a passphrase (optional – press Enter for none).
6. The script will:
   - Generate a new SSH key.
   - Add it to `ssh-agent`.
   - Copy the `.pub` key to your clipboard.
   - Show the fingerprint and test GitHub.

---

## Adding the Key to GitHub
1. Go to [GitHub → Settings → SSH and GPG keys](https://github.com/settings/keys).
2. Click **New SSH key**.
3. Paste the key from your clipboard.
4. Save.

---

## Testing the Setup
The script runs a test automatically:

```powershell
ssh -T git@github.com
```

If everything is configured correctly, you should see:

```
Hi <your-username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## Example Output

Running the script typically looks like this (your output may vary):

```
== GitHub SSH Key Setup ==
Enter your GitHub email address: you@example.com
Enter a passphrase (or leave blank for none):

Generating SSH key...
Key added to ssh-agent.
Your public key has been copied to the clipboard.
Paste it into GitHub -> Settings -> SSH and GPG keys -> New SSH key.
256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx you@example.com (ED25519)

Testing GitHub connection...
Hi you! You've successfully authenticated, but GitHub does not provide shell access.
```

### Notes on Output Variations
- If `ssh-agent` is **already running**, you may not see the "started" message.  
- If `ssh-agent` fails to start, the script prints a warning and you can start it manually.  
- If you already have a key, the script will back it up and tell you where it was saved.  
- The GitHub connection test may show a warning the first time:
  ```
  The authenticity of host 'github.com (IP)' can't be established.
  Are you sure you want to continue connecting (yes/no/[fingerprint])?
  ```
  Type `yes` to continue.

---

## Troubleshooting

### `ssh-agent` cannot be started
- Ensure you are running PowerShell **as Administrator**.
- Try enabling the service manually:
  ```powershell
  Set-Service -Name ssh-agent -StartupType Automatic
  Start-Service ssh-agent
  ```
- As a fallback, run:
  ```powershell
  sc.exe config ssh-agent start=auto
  sc.exe start ssh-agent
  ```

### `Permission denied (publickey)` when testing
- Confirm your public key was copied correctly:
  ```powershell
  Get-Content $HOME\.ssh\id_ed25519.pub
  ```
- Ensure you pasted it into GitHub under  
  **Settings → SSH and GPG keys → New SSH key**.
- Verify your key is loaded into the agent:
  ```powershell
  ssh-add -l
  ```
  If no key is listed, add it manually:
  ```powershell
  ssh-add $HOME\.ssh\id_ed25519
  ```

### No `ssh-keygen` found
- Install the OpenSSH Client:
  ```powershell
  Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
  ```

---

## Notes
- Existing keys (`id_ed25519` and `id_ed25519.pub`) are automatically backed up with a timestamp.
- Ed25519 is the recommended algorithm. Use RSA 4096-bit only if Ed25519 isn’t supported.
- The script is designed for **GitHub**, but the key can also be used for other services (GitLab, Bitbucket, etc.).

---
