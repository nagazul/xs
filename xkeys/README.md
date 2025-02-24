README.txt for xkeys - Enhanced SSH Agent Management
===================================================

Overview
--------
xkeys is a Bash script for managing SSH agents and keys securely. It supports
multi-key handling, encrypted passphrases, and agent lifecycle management.

Features:
- Securely add, remove, and load SSH keys
- Encrypt key passphrases with a master password
- Scan, verify, and clean SSH key configurations
- Manage SSH agent lifecycle

Setup
-----
1. Save the script as ~/.xkeys
2. Add to .bashrc: [ -f "$HOME/.xkeys" ] && . "$HOME/.xkeys" #2>/dev/null
3. Reload shell: source ~/.bashrc
4. Install dependencies: ssh-agent, ssh-add, openssl, expect

Usage Examples
--------------
1. Add a key:
   $ xkeys add ~/.ssh/id_rsa
   Enter SSH key passphrase for /home/user/.ssh/id_rsa: ****
   Enter Master Password to encrypt this key: ****
   Key '/home/user/.ssh/id_rsa' registered.

2. List loaded keys:
   $ xkeys ls
   SSH agent is running with the following keys:
   256 SHA256:abc123 user@host (RSA)

3. Scan for keys:
   $ xkeys scan
   Scanning for SSH keys in: /home/user/.ssh (recursively)
   Key Path            Security    Status    Agent
   ------------------- ---------- ---------- ----------
   /home/user/.ssh/id_rsa ENCRYPTED  ADDED     LOADED

4. Load all managed keys:
   $ xkeys load
   Enter Master Password to decrypt passphrase for /home/user/.ssh/id_rsa: ****
   Successfully loaded 1 of 1 keys.

5. Remove a key:
   $ xkeys rm ~/.ssh/id_rsa
   Key removed: /home/user/.ssh/id_rsa

6. Change master password:
   $ xkeys passwd
   Enter current Master Password: ****
   Enter new Master Password: ****
   Confirm new Master Password: ****
   Master Password updated for all keys (1 of 1).

7. Clean up:
   $ xkeys clean
   Cleanup complete. Cleaned 0 of 2 items.

8. Kill agent:
   $ xkeys kill
   All SSH agents have been terminated and cleaned up.

Commands
--------
xkeys <command> [args]:
- ls          Show loaded keys
- scan [dir]  Scan for keys
- add <path>  Add key
- rm <path>   Remove key
- load        Load all keys
- kill        Stop agent
- clean       Clean temp files
- purge --force  Remove all data
- verify      Verify keys
- passwd      Change master password

Notes
-----
- Requires Bash 4+
- Uses /dev/shm or /tmp for temp files
- Debug mode: export DEBUG_MODE=1
