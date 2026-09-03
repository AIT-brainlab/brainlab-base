#!/usr/bin/env python3
"""
AIT Brainlab - Automated SSH Key Rotation Tool
Performs a zero-lockout, dual-key staged rotation of brainlab-admin-key across all servers.
"""

import os
import sys
import tempfile
import subprocess
import argparse
from datetime import datetime

TARGET_SERVERS = [
    ("brainlab-mgmt-vm", "ubuntu"),
    ("brainlab-proxy",   "ubuntu"),
    ("brainlab-services", "ubuntu"),
    ("dlms-server",      "ubuntu"),
]

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
PUB_KEY_PATH = os.path.join(REPO_ROOT, "mgmt/keys/brainlab-admin-key.pub")

def run_ssh(key_path, user, host, command, timeout=5):
    cmd = [
        "ssh",
        "-i", key_path,
        "-o", "ConnectTimeout=" + str(timeout),
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        f"{user}@{host}",
        command
    ]
    return subprocess.run(cmd, capture_output=True, text=True)

def main():
    parser = argparse.ArgumentParser(description="Automated zero-lockout rotation of brainlab-admin-key")
    parser.add_argument("--current-key", default=os.path.expanduser("~/.ssh/brainlab-admin-key"),
                        help="Path to current working private key (default: ~/.ssh/brainlab-admin-key)")
    parser.add_argument("--out-dir", default=os.path.expanduser("~/.ssh"),
                        help="Directory to save the new keypair (default: ~/.ssh)")
    parser.add_argument("--dry-run", action="store_true", help="Simulate rotation without modifying servers")
    args = parser.parse_args()

    print("==========================================================")
    print("🔄 AIT Brainlab - Automated SSH Admin Key Rotation")
    print(f"   Current Key : {args.current_key}")
    print(f"   Target Nodes: {len(TARGET_SERVERS)} servers")
    print(f"   Mode        : {'DRY RUN' if args.dry_run else 'LIVE ROTATION'}")
    print("==========================================================")

    if not os.path.exists(args.current_key):
        print(f"❌ Error: Current private key not found at {args.current_key}", file=sys.stderr)
        sys.exit(1)

    # 1. Pre-flight check: Verify current key connects to all targets
    print("\n🔍 Step 1: Pre-flight Verification (Testing Current Key)...")
    for peer_name, user in TARGET_SERVERS:
        res = run_ssh(args.current_key, user, peer_name, "hostname")
        if res.returncode == 0:
            print(f"  ✅ {peer_name:20} -> OK")
        else:
            print(f"  ❌ {peer_name:20} -> FAILED ({res.stderr.strip()})")
            print("\n❌ Pre-flight failed. Aborting rotation to prevent lockout.", file=sys.stderr)
            sys.exit(1)

    if args.dry_run:
        print("\n🎉 Dry run completed successfully. All NetBird peers reachable by hostname.")
        return

    # 2. Generate New ED25519 Keypair
    year = datetime.now().year
    tmp_dir = tempfile.mkdtemp()
    new_priv_key = os.path.join(tmp_dir, "brainlab-admin-key")
    comment = f"brainlab-admin-key-{year}"

    print(f"\n🔑 Step 2: Generating New ED25519 Keypair ({comment})...")
    subprocess.run(["ssh-keygen", "-t", "ed25519", "-C", comment, "-N", "", "-f", new_priv_key],
                   stdout=subprocess.DEVNULL, check=True)

    with open(new_priv_key + ".pub", "r") as f:
        new_pub_content = f.read().strip()

    # Read old public key content for later cleanup
    old_pub_content = ""
    if os.path.exists(PUB_KEY_PATH):
        with open(PUB_KEY_PATH, "r") as f:
            old_pub_content = f.read().strip()

    # 3. Stage New Public Key (Dual-Key State)
    print("\n➕ Step 3: Staging New Public Key on All Peers (Dual-Key State)...")
    for peer_name, user in TARGET_SERVERS:
        inject_cmd = f"sudo mkdir -p /home/{user}/.ssh && echo '{new_pub_content}' | sudo tee -a /home/{user}/.ssh/authorized_keys >/dev/null 2>&1 || (sudo mkdir -p /root/.ssh && echo '{new_pub_content}' | sudo tee -a /root/.ssh/authorized_keys >/dev/null)"
        res = run_ssh(args.current_key, user, peer_name, inject_cmd)
        if res.returncode == 0:
            print(f"  ✅ Injected new key to {peer_name} ({user})")
        else:
            print(f"  ❌ Failed to inject on {peer_name}: {res.stderr.strip()}")
            sys.exit(1)

    # 4. Verify New Key Connectivity (Zero-Lockout Verification)
    print("\n🧪 Step 4: Verifying Connectivity with New Key...")
    for peer_name, user in TARGET_SERVERS:
        res = run_ssh(new_priv_key, user, peer_name, "hostname")
        if res.returncode == 0:
            print(f"  ✅ {peer_name:20} -> VERIFIED NEW KEY")
        else:
            print(f"  ❌ FAILED on {peer_name} with new key! Aborting cleanup.", file=sys.stderr)
            sys.exit(1)

    # 5. Prune Old Public Key from All Peers
    if old_pub_content:
        old_fingerprint_token = old_pub_content.split()[1] if len(old_pub_content.split()) > 1 else "brainlab-admin-key"
        print(f"\n🧹 Step 5: Pruning Old Key from All Peers...")
        for peer_name, user in TARGET_SERVERS:
            prune_cmd = f"sudo sed -i '/{old_fingerprint_token}/d' /home/{user}/.ssh/authorized_keys 2>/dev/null || sudo sed -i '/{old_fingerprint_token}/d' /root/.ssh/authorized_keys 2>/dev/null"
            res = run_ssh(new_priv_key, user, peer_name, prune_cmd)
            if res.returncode == 0:
                print(f"  ✅ Pruned old key from {peer_name}")

    # 6. Update Repository Public Key
    print(f"\n💾 Step 6: Updating Repository Public Key ({PUB_KEY_PATH})...")
    os.makedirs(os.path.dirname(PUB_KEY_PATH), exist_ok=True)
    with open(PUB_KEY_PATH, "w") as f:
        f.write(new_pub_content + "\n")
    print(f"  ✅ Saved new public key to {PUB_KEY_PATH}")

    # 7. Output Final Credentials
    dest_priv = os.path.join(args.out_dir, f"brainlab-admin-key-{year}")
    dest_pub = dest_priv + ".pub"
    with open(dest_priv, "w") as f:
        with open(new_priv_key, "r") as src:
            f.write(src.read())
    os.chmod(dest_priv, 0o600)

    with open(dest_pub, "w") as f:
        f.write(new_pub_content + "\n")

    print("\n==========================================================")
    print("🎉 Key Rotation Completed Successfully (Zero Downtime)!")
    print(f"   New Private Key: {dest_priv}")
    print(f"   New Public Key : {dest_pub}")
    print("==========================================================")
    print("👉 Next Actions:")
    print("   1. Commit mgmt/keys/brainlab-admin-key.pub to git.")
    print("   2. Update GitHub Secret VM_SSH_PRIVATE_KEY with the new private key.")
    print("   3. Replace your ~/.ssh/brainlab-admin-key with the new key.")
    print("==========================================================")

if __name__ == "__main__":
    main()
