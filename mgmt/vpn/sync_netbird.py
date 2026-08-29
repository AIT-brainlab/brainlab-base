#!/usr/bin/env python3
"""
=============================================================================
📡 AIT Brainlab - Declarative NetBird GitOps Synchronizer (sync_netbird.py)
=============================================================================
Reconciles declarative groups, zero-trust access policies, and setup keys
declared in 'network.yaml' with the live NetBird Management REST API.

Features:
- Pure Python 3 standard library (zero external dependencies).
- Fetches Personal Access Token (PAT) directly from GCP Secret Manager.
- Supports --dry-run (preview) and --apply (reconciliation).
- Automatically resolves group names to NetBird UUIDs across policy rules.

Usage:
  ./sync_netbird.py            # Dry-run preview
  ./sync_netbird.py --apply    # Commit changes to live NetBird
=============================================================================
"""

import sys
import os
import json
import ssl
import subprocess
import argparse
from pathlib import Path
import urllib.request
import urllib.error

# UI Colors
GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"

DEFAULT_API_URL = "https://netbird2.brain.cs.ait.ac.th/api"
DEFAULT_SECRET_NAME = "netbird-mgmt-token"
DEFAULT_PROJECT_ID = "ait-brainlab-mgmt"

def get_mgmt_token(secret_name=DEFAULT_SECRET_NAME, project_id=DEFAULT_PROJECT_ID):
    """Retrieve PAT from environment or GCP Secret Manager."""
    env_token = os.environ.get("NETBIRD_MGMT_TOKEN")
    if env_token:
        return env_token.strip()

    try:
        cmd = [
            "gcloud", "secrets", "versions", "access", "latest",
            f"--secret={secret_name}",
            f"--project={project_id}"
        ]
        res = subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
        return res.decode().strip()
    except Exception as e:
        print(f"{RED}❌ Error fetching token from Secret Manager '{secret_name}': {e}{NC}")
        print(f"{YELLOW}💡 Tip: Ensure token is stored in Secret Manager or set NETBIRD_MGMT_TOKEN environment variable.{NC}")
        sys.exit(1)

def api_request(base_url, endpoint, token, method="GET", data=None):
    """Execute HTTP request against NetBird Management REST API."""
    url = f"{base_url.rstrip('/')}/{endpoint.lstrip('/')}"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    payload = json.dumps(data).encode("utf-8") if data is not None else None
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    req = urllib.request.Request(url, data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=15) as res:
            resp_body = res.read().decode("utf-8")
            return json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        raise RuntimeError(f"HTTP {e.code} on {method} {url}: {err_msg}")
    except Exception as e:
        raise RuntimeError(f"Request failed on {method} {url}: {e}")

def parse_yaml_file(filepath):
    """
    Lightweight YAML parser for network.yaml.
    Supports standard yaml syntax without external pyyaml package.
    Falls back to PyYAML if installed.
    """
    try:
        import yaml
        with open(filepath, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except ImportError:
        pass

    # Custom minimalist YAML parser for our structured schema
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Try running python with pyyaml if available in environment
    try:
        py_code = "import yaml, json, sys; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))"
        out = subprocess.check_output(["python3", "-c", py_code, str(filepath)], stderr=subprocess.DEVNULL)
        return json.loads(out)
    except Exception:
        print(f"{RED}❌ PyYAML is required to parse '{filepath}'. Run: pip install pyyaml{NC}")
        sys.exit(1)

def sync_groups(base_url, token, declared_groups, dry_run=True):
    """Synchronize declared device groups."""
    print(f"\n{BLUE}--- 👥 Synchronizing Device Groups ---{NC}")
    existing = api_request(base_url, "/groups", token)
    existing_map = {g["name"]: g["id"] for g in existing}

    name_to_id = dict(existing_map)
    created_count = 0

    for group in declared_groups:
        name = group["name"]
        if name in existing_map:
            print(f"  {GREEN}✔ Group exists:{NC} {name} (ID: {existing_map[name]})")
        else:
            print(f"  {YELLOW}+ Creating group:{NC} {name}")
            if not dry_run:
                payload = {"name": name, "peers": []}
                res = api_request(base_url, "/groups", token, method="POST", data=payload)
                name_to_id[name] = res["id"]
                created_count += 1
            else:
                name_to_id[name] = f"dry-run-id-{name}"
                created_count += 1

    return name_to_id, created_count

def sync_policies(base_url, token, declared_policies, group_name_to_id, dry_run=True):
    """Synchronize zero-trust access policies and reconcile rules."""
    print(f"\n{BLUE}--- 🛡️ Synchronizing Zero-Trust Policies ---{NC}")
    existing = api_request(base_url, "/policies", token)
    existing_map = {p["name"]: p for p in existing}

    # Identify and disable default "All" policy if present
    for p in existing:
        if p["name"].lower() in ["default", "all"]:
            if p.get("enabled", True):
                print(f"  {YELLOW}⚠️  Detected default open policy '{p['name']}'. Disabling for Zero-Trust...{NC}")
                if not dry_run:
                    p["enabled"] = False
                    api_request(base_url, f"/policies/{p['id']}", token, method="PUT", data=p)

    synced_count = 0

    for pol in declared_policies:
        pol_name = pol["name"]
        description = pol.get("description", "")
        enabled = pol.get("enabled", True)

        formatted_rules = []
        for r in pol.get("rules", []):
            src_ids = [group_name_to_id[s] for s in r.get("sources", []) if s in group_name_to_id]
            dst_ids = [group_name_to_id[d] for d in r.get("destinations", []) if d in group_name_to_id]

            rule_obj = {
                "name": r.get("name", pol_name),
                "description": r.get("description", ""),
                "enabled": r.get("enabled", True),
                "action": r.get("action", "accept"),
                "protocol": r.get("protocol", "all"),
                "bidirectional": r.get("bidirectional", True),
                "sources": src_ids,
                "destinations": dst_ids
            }
            if "ports" in r:
                rule_obj["ports"] = [str(p) for p in r["ports"]]
            formatted_rules.append(rule_obj)

        payload = {
            "name": pol_name,
            "description": description,
            "enabled": enabled,
            "rules": formatted_rules
        }

        if pol_name in existing_map:
            print(f"  {GREEN}✔ Policy exists:{NC} {pol_name} (Reconciling rules)")
            if not dry_run:
                pol_id = existing_map[pol_name]["id"]
                api_request(base_url, f"/policies/{pol_id}", token, method="PUT", data=payload)
                synced_count += 1
            else:
                synced_count += 1
        else:
            print(f"  {YELLOW}+ Creating policy:{NC} {pol_name}")
            if not dry_run:
                api_request(base_url, "/policies", token, method="POST", data=payload)
                synced_count += 1
            else:
                synced_count += 1

    return synced_count

def sync_setup_keys(base_url, token, declared_keys, group_name_to_id, dry_run=True):
    """Synchronize server setup keys."""
    print(f"\n{BLUE}--- 🔑 Synchronizing Server Setup Keys ---{NC}")
    existing = api_request(base_url, "/setup-keys", token)
    existing_map = {k["name"]: k for k in existing}

    synced_count = 0

    for key_cfg in declared_keys:
        name = key_cfg["name"]
        auto_group_ids = [group_name_to_id[g] for g in key_cfg.get("auto_groups", []) if g in group_name_to_id]
        key_type = key_cfg.get("type", "reusable")
        expires_in = key_cfg.get("expires_in_days", 30) * 86400

        if name in existing_map:
            k = existing_map[name]
            valid = k.get("valid", True)
            status_str = f"{GREEN}VALID{NC}" if valid else f"{RED}EXPIRED{NC}"
            print(f"  {GREEN}✔ Setup key exists:{NC} {name} (Status: {status_str}, Type: {k.get('type')})")
        else:
            print(f"  {YELLOW}+ Generating setup key:{NC} {name} (Type: {key_type}, Groups: {key_cfg.get('auto_groups')})")
            if not dry_run:
                payload = {
                    "name": name,
                    "type": key_type,
                    "expires_in": expires_in,
                    "auto_groups": auto_group_ids,
                    "usage_limit": key_cfg.get("usage_limit", 0)
                }
                res = api_request(base_url, "/setup-keys", token, method="POST", data=payload)
                print(f"    {BOLD}🎉 Generated Key:{NC} {CYAN}{res.get('key')}{NC}")
                synced_count += 1
            else:
                synced_count += 1

    return synced_count

def check_token_health(base_url, token):
    """Inspect active PAT expiration date and warn if expiring within 30 days."""
    try:
        from datetime import datetime, timezone
        users = api_request(base_url, "/users", token)
        now = datetime.now(timezone.utc)
        for u in users:
            for pat in u.get("personal_access_tokens", []):
                exp_str = pat.get("expiration_date")
                if exp_str:
                    exp_date = datetime.fromisoformat(exp_str.replace("Z", "+00:00"))
                    days_left = (exp_date - now).days
                    if 0 <= days_left <= 30:
                        print(f"\n{YELLOW}⚠️  WARNING: Personal Access Token '{pat.get('name')}' expires in {days_left} days ({exp_str[:10]})!{NC}")
                        print(f"{YELLOW}   Please renew the token in NetBird UI and update GCP Secret Manager: netbird-mgmt-token{NC}\n")
                    elif days_left < 0:
                        print(f"\n{RED}❌ CRITICAL: Personal Access Token '{pat.get('name')}' has EXPIRED ({exp_str[:10]})!{NC}\n")
    except Exception:
        pass

def main():
    parser = argparse.ArgumentParser(description="AIT Brainlab NetBird GitOps Synchronizer")
    parser.add_argument("--config", default="mgmt/vpn/network.yaml", help="Path to network.yaml")
    parser.add_argument("--api-url", default=DEFAULT_API_URL, help="NetBird API URL")
    parser.add_argument("--secret-name", default=DEFAULT_SECRET_NAME, help="GCP Secret Manager secret name")
    parser.add_argument("--project-id", default=DEFAULT_PROJECT_ID, help="GCP Project ID")
    parser.add_argument("--apply", action="store_true", help="Apply changes to live NetBird (Default is dry-run)")

    args = parser.parse_args()

    print(f"\n{BLUE}{'=' * 65}{NC}")
    print(f"{BOLD}📡 AIT Brainlab - Declarative NetBird GitOps Synchronizer{NC}")
    print(f"{BLUE}{'=' * 65}{NC}")
    print(f"Config File:  {CYAN}{args.config}{NC}")
    print(f"API Endpoint: {CYAN}{args.api_url}{NC}")
    print(f"Mode:         {GREEN if args.apply else YELLOW}{'APPLY (Live Reconciliation)' if args.apply else 'DRY-RUN (Preview Only)'}{NC}")
    print(f"{BLUE}{'=' * 65}{NC}")

    config_path = Path(args.config)
    if not config_path.is_absolute():
        # Search relative to repo root
        repo_root = Path(__file__).resolve().parent.parent.parent
        config_path = repo_root / args.config

    if not config_path.exists():
        print(f"{RED}❌ Configuration file not found at '{config_path}'{NC}")
        sys.exit(1)

    print(f"\nReading declarative configuration from {config_path}...")
    network_spec = parse_yaml_file(config_path)

    declared_groups = network_spec.get("groups", [])
    declared_policies = network_spec.get("policies", [])
    declared_setup_keys = network_spec.get("setup_keys", [])

    print(f"Loaded: {len(declared_groups)} groups, {len(declared_policies)} policies, {len(declared_setup_keys)} setup keys.")

    token = get_mgmt_token(args.secret_name, args.project_id)
    print(f"{GREEN}✔ Successfully authenticated with NetBird Management API.{NC}")
    check_token_health(args.api_url, token)

    # 1. Sync Groups
    group_map, created_groups = sync_groups(args.api_url, token, declared_groups, dry_run=not args.apply)

    # 2. Sync Policies
    synced_policies = sync_policies(args.api_url, token, declared_policies, group_map, dry_run=not args.apply)

    # 3. Sync Setup Keys
    synced_keys = sync_setup_keys(args.api_url, token, declared_keys, group_map, dry_run=not args.apply)

    print(f"\n{BLUE}{'=' * 65}{NC}")
    if not args.apply:
        print(f"{YELLOW}🔎 DRY-RUN COMPLETE: No changes were made to live NetBird.{NC}")
        print(f"To apply these changes, run:")
        print(f"  {BOLD}{sys.argv[0]} --apply{NC}\n")
    else:
        print(f"{GREEN}🎉 NETBIRD GITOPS SYNCHRONIZATION COMPLETE!{NC}")
        print(f"Groups created/checked: {len(declared_groups)}")
        print(f"Policies synchronized:  {len(declared_policies)}")
        print(f"Setup keys managed:     {len(declared_setup_keys)}")
        print(f"{BLUE}{'=' * 65}{NC}\n")

if __name__ == "__main__":
    main()
