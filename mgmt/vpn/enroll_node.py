#!/usr/bin/env python3
"""
AIT Brainlab - NetBird Node Enrollment CLI (Day 1 Onboarding)
Enrolls an on-premise Proxmox VM or physical node into NetBird mesh via SSH.
"""

import sys
import os
import argparse
import subprocess

PROJECT_ID = "ait-brainlab-mgmt"
DEFAULT_SSH_KEY = os.path.expanduser("~/.ssh/brainlab-admin-key")
BOOTSTRAP_SCRIPT_URL = "https://raw.githubusercontent.com/AIT-brainlab/brainlab-base/main/docs/infra/onprem/scripts/bootstrap_netbird_csim.sh"

def get_mgmt_token():
    if os.environ.get("NETBIRD_MGMT_TOKEN"):
        return os.environ["NETBIRD_MGMT_TOKEN"]
    try:
        cmd = f"gcloud secrets versions access latest --secret=netbird-mgmt-token --project={PROJECT_ID}"
        token = subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
        return token
    except Exception:
        return None

def generate_ephemeral_key(group_name):
    from sync_netbird import api_request
    token = get_mgmt_token()
    if not token:
        print("❌ Could not fetch netbird-mgmt-token from GCP Secret Manager.")
        sys.exit(1)

    base_url = "https://netbird.brain.cs.ait.ac.th/api"
    # Resolve group ID
    groups = api_request(base_url, "/groups", token)
    group_map = {g["name"]: g["id"] for g in groups}
    
    if group_name not in group_map:
        print(f"❌ Error: Group '{group_name}' not found in NetBird.")
        sys.exit(1)

    group_id = group_map[group_name]
    print(f"🔑 Generating 1-time setup key for group '{group_name}' (ID: {group_id})...")
    payload = {
        "name": f"ephemeral-enroll-{group_name}",
        "type": "one-off",
        "expires_in": 3600, # 1 hour
        "auto_groups": [group_id],
        "usage_limit": 1
    }
    res = api_request(base_url, "/setup-keys", token, method="POST", data=payload)
    key = res.get("key")
    if not key:
        print(f"❌ Failed to generate key: {res}")
        sys.exit(1)
    return key

def main():
    parser = argparse.ArgumentParser(description="Enroll a server into NetBird WireGuard mesh via SSH")
    parser.add_argument("--host", required=True, help="Target host IP or domain (e.g. 10.10.250.120, 192.41.170.39)")
    parser.add_argument("--user", default="ubuntu", help="SSH username (default: ubuntu)")
    parser.add_argument("--key-file", default=DEFAULT_SSH_KEY, help="Path to SSH private key")
    parser.add_argument("--group", default="brainlab-cluster", help="NetBird auto-group (default: brainlab-cluster)")
    parser.add_argument("--setup-key", help="Explicit setup key (if not provided, generates dynamically via API)")
    args = parser.parse_args()

    print("==========================================================")
    print("📡 AIT Brainlab NetBird Node Onboarding Tool")
    print(f"   Target Host: {args.user}@{args.host}")
    print(f"   SSH Key:     {args.key_file}")
    print(f"   Group:       {args.group}")
    print("==========================================================")

    # 1. Resolve Setup Key
    setup_key = args.setup_key
    if not setup_key:
        setup_key = generate_ephemeral_key(args.group)
        print(f"✅ Generated single-use setup key: {setup_key[:8]}****")

    # 2. Execute Bootstrap over SSH
    print(f"\n🚀 Connecting to {args.host} via SSH and executing NetBird bootstrap...")
    remote_cmd = f"curl -fsSL {BOOTSTRAP_SCRIPT_URL} | sudo bash -s -- {setup_key}"

    ssh_cmd = [
        "ssh",
        "-i", args.key_file,
        "-o", "StrictHostKeyChecking=accept-new",
        f"{args.user}@{args.host}",
        remote_cmd
    ]

    res = subprocess.run(ssh_cmd)
    if res.returncode == 0:
        print("\n🎉 Node enrolled successfully into NetBird mesh!")
    else:
        print(f"\n❌ SSH execution failed with exit code {res.returncode}")
        sys.exit(res.returncode)

if __name__ == "__main__":
    main()
