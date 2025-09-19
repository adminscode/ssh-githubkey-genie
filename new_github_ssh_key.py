import os
import subprocess
import shutil
import getpass
import platform
import sys
import json
from datetime import datetime

try:
    import requests  # type: ignore
except Exception:
    import urllib.request
    import urllib.error

    class _SimpleResponse:
        def __init__(self, status_code, text):
            self.status_code = status_code
            self.text = text

        def json(self):
            try:
                return json.loads(self.text)
            except Exception:
                return None

    class _RequestsShim:
        @staticmethod
        def _request(method, url, headers=None, data=None):
            if headers is None:
                headers = {}
            req_data = None
            if data is not None:
                # data may be bytes or a str
                req_data = data.encode("utf-8") if isinstance(data, str) else data
                # ensure a content-type if not provided and data looks like JSON
                if "Content-Type" not in {k.title(): v for k, v in (headers.items() if isinstance(headers, dict) else [])} and isinstance(data, str):
                    headers.setdefault("Content-Type", "application/json")
            req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
            try:
                with urllib.request.urlopen(req) as resp:
                    body = resp.read().decode("utf-8")
                    return _SimpleResponse(resp.getcode(), body)
            except urllib.error.HTTPError as e:
                try:
                    body = e.read().decode("utf-8")
                except Exception:
                    body = ""
                return _SimpleResponse(e.code, body)
            except Exception as e:
                return _SimpleResponse(0, str(e))

        @staticmethod
        def get(url, headers=None):
            return _RequestsShim._request("GET", url, headers=headers)

        @staticmethod
        def post(url, headers=None, data=None):
            return _RequestsShim._request("POST", url, headers=headers, data=data)

    requests = _RequestsShim()


def run_command(command, check=True, capture_output=False, text=True, shell=True, input=None):
    return subprocess.run(
        command,
        check=check,
        capture_output=capture_output,
        text=text,
        shell=shell,
        input=input
    )


def command_exists(cmd):
    return shutil.which(cmd) is not None


def install_package(pkg):
    system = platform.system()
    distro = ""
    if system == "Linux":
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("ID="):
                        distro = line.strip().split("=")[1].replace('"', "")
                        break
        except FileNotFoundError:
            pass

        if distro in ["ubuntu", "debian"]:
            run_command(f"sudo apt-get update && sudo apt-get install -y {pkg}", check=True)
        elif distro in ["fedora", "centos", "rhel"]:
            run_command(f"sudo dnf install -y {pkg} || sudo yum install -y {pkg}", check=True)
        else:
            print(f"Could not detect supported package manager. Please install {pkg} manually.")
    elif system == "Darwin":
        print(f"Please install {pkg} via Homebrew: brew install {pkg}")
    elif system == "Windows":
        print(f"On Windows, install OpenSSH Client via Settings or PowerShell:\n"
              f'Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0')
    else:
        print(f"Unsupported system. Please install {pkg} manually.")


def ensure_ssh_tools():
    missing = []
    for tool in ["ssh-keygen", "ssh-agent", "ssh-add"]:
        if not command_exists(tool):
            missing.append(tool)

    if missing:
        print(f"Missing tools: {', '.join(missing)}. Attempting to install OpenSSH...")
        install_package("openssh-client")


def ensure_xclip():
    if platform.system() == "Linux" and not command_exists("xclip"):
        print("xclip not found. Attempting to install...")
        install_package("xclip")


def copy_to_clipboard(file_path):
    with open(file_path, "r") as f:
        key_content = f.read()

    system = platform.system()
    if system == "Windows":
        subprocess.run("clip", input=key_content.strip(), text=True, shell=True)
        print("Your public key has been copied to the clipboard (Windows).")
    elif system == "Darwin":
        run_command(f'echo "{key_content.strip()}" | pbcopy')
        print("Your public key has been copied to the clipboard (macOS).")
    elif system == "Linux":
        ensure_xclip()
        try:
            run_command(f'echo "{key_content.strip()}" | xclip -selection clipboard')
            print("Your public key has been copied to the clipboard (Linux).")
        except Exception as e:
            print(f"Failed to copy key to clipboard. Key is located at {file_path}. Error: {e}")
    else:
        print(f"Unsupported OS: {system}. Public key is located at {file_path}")


def validate_github_token(token):
    url = "https://api.github.com/user"
    headers = {"Authorization": f"token {token}"}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        user = response.json().get("login", "unknown")
        print(f"GitHub token validated. Authenticated as {user}.")
        return True
    else:
        print(f"Invalid GitHub token. Status: {response.status_code}, Response: {response.text}")
        return False


def upload_to_github(pubkey):
    print("\n== GitHub API Upload ==")
    token = ""
    while not token:
        token = getpass.getpass("Enter your GitHub Personal Access Token (classic, with admin:public_key scope): ").strip()
        if not token:
            print("A token is required to upload the key to GitHub. Please try again.")

    if not validate_github_token(token):
        print("Token validation failed. Aborting GitHub upload.")
        return

    title = f"SSH Key {platform.node()} {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    url = "https://api.github.com/user/keys"
    headers = {"Authorization": f"token {token}"}
    data = {"title": title, "key": pubkey}

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 201:
        print("Public key uploaded successfully to GitHub.")
    else:
        print(f"Failed to upload key. Status: {response.status_code}, Response: {response.text}")


def checklist():
    print("== Prerequisite Checklist ==")
    print(f"- Python version: {sys.version.split()[0]} (requires >= 3.6)")
    print(f"- OS detected: {platform.system()}")
    print("- Checking required tools:")

    tools = {
        "ssh-keygen": "Generate SSH keys",
        "ssh-agent": "Manage SSH agent",
        "ssh-add": "Add keys to agent",
        "clip/pbcopy/xclip": "Copy keys to clipboard",
    }

    for tool, desc in tools.items():
        if tool == "clip/pbcopy/xclip":
            if platform.system() == "Windows" and not command_exists("clip"):
                print(f"Missing: {desc}")
            elif platform.system() == "Darwin" and not command_exists("pbcopy"):
                print(f"Missing: {desc}")
            elif platform.system() == "Linux" and not command_exists("xclip"):
                print(f"Missing: {desc}")
            else:
                print(f"Present: {desc}")
        else:
            print(f"Present: {desc}" if command_exists(tool) else f"Missing: {desc}")


def main():
    print("== GitHub SSH Key Setup ==")
    checklist()

    # Ensure requirements
    ensure_ssh_tools()

    email = ""
    while not email:
        email = input("\nEnter your GitHub email address: ").strip()
        if not email:
            print("Email cannot be empty. Please try again.")

    passphrase = getpass.getpass("Enter a passphrase (or leave blank for none): ")

    ssh_dir = os.path.expanduser("~/.ssh")
    os.makedirs(ssh_dir, exist_ok=True)

    private_key = os.path.join(ssh_dir, "id_ed25519")
    public_key = private_key + ".pub"

    # Backup old keys
    if os.path.exists(private_key):
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        shutil.move(private_key, private_key + f".bak.{timestamp}")
        if os.path.exists(public_key):
            shutil.move(public_key, public_key + f".bak.{timestamp}")
        print("Existing keys backed up.")

    print("\nGenerating SSH key...")
    run_command(f'ssh-keygen -t ed25519 -C "{email}" -f "{private_key}" -N "{passphrase}"')

    # Start ssh-agent
    try:
        run_command("eval $(ssh-agent -s)", check=False)
    except Exception as e:
        print(f"Warning: ssh-agent may already be running: {e}")

    # Add key to agent
    run_command(f'ssh-add "{private_key}"')

    # Copy public key
    copy_to_clipboard(public_key)

    # Show fingerprint
    result = run_command(f'ssh-keygen -lf "{public_key}"', capture_output=True)
    print("\nFingerprint:")
    print(result.stdout.strip())

    # Upload to GitHub
    with open(public_key, "r") as f:
        pubkey = f.read().strip()
    upload_to_github(pubkey)

    # Test GitHub connection
    print("\nTesting GitHub connection...")
    result = run_command("ssh -T git@github.com", capture_output=True, check=False)
    print(result.stdout.strip() or result.stderr.strip())


if __name__ == "__main__":
    main()
