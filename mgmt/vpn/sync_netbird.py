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

DEFAULT_API_URL = "https://netbird.brain.cs.ait.ac.th/api"
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
    Zero-dependency YAML parser tailored for network.yaml.
    Falls back to PyYAML if installed.
    """
    try:
        import yaml
        with open(filepath, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except ImportError:
        pass

    import re
    result = {"groups": [], "policies": [], "setup_keys": [], "dns_zones": []}
    current_section = None
    current_item = None
    current_rule = None

    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            raw = line.rstrip()
            stripped = raw.strip()
            if not stripped or stripped.startswith("#"):
                continue

            if stripped == "groups:":
                current_section = "groups"
                current_item = None
                continue
            elif stripped == "policies:":
                current_section = "policies"
                current_item = None
                continue
            elif stripped == "setup_keys:":
                current_section = "setup_keys"
                current_item = None
                continue
            elif stripped == "dns_zones:":
                current_section = "dns_zones"
                current_item = None
                continue

            if current_section == "groups":
                if stripped.startswith("- name:"):
                    name = stripped.split(":", 1)[1].strip()
                    current_item = {"name": name}
                    result["groups"].append(current_item)
                elif current_item and stripped.startswith("description:"):
                    current_item["description"] = stripped.split(":", 1)[1].strip().strip('"\'')

            elif current_section == "policies":
                if raw.startswith("  - name:"):
                    name = stripped.split(":", 1)[1].strip()
                    current_item = {"name": name, "rules": []}
                    result["policies"].append(current_item)
                    current_rule = None
                elif current_item:
                    if raw.startswith("      - name:"):
                        r_name = stripped.split(":", 1)[1].strip()
                        current_rule = {"name": r_name}
                        current_item["rules"].append(current_rule)
                    elif stripped.startswith("description:"):
                        current_item["description"] = stripped.split(":", 1)[1].strip().strip('"\'')
                    elif stripped.startswith("enabled:"):
                        current_item["enabled"] = stripped.split(":", 1)[1].strip().lower() == "true"
                    elif stripped == "rules:":
                        pass
                    elif current_rule:
                        if stripped.startswith("action:"):
                            current_rule["action"] = stripped.split(":", 1)[1].strip()
                        elif stripped.startswith("protocol:"):
                            current_rule["protocol"] = stripped.split(":", 1)[1].strip()
                        elif stripped.startswith("bidirectional:"):
                            current_rule["bidirectional"] = stripped.split(":", 1)[1].strip().lower() == "true"
                        elif stripped.startswith("sources:"):
                            m = re.search(r"\[(.*)\]", stripped)
                            if m:
                                current_rule["sources"] = [s.strip() for s in m.group(1).split(",") if s.strip()]
                        elif stripped.startswith("destinations:"):
                            m = re.search(r"\[(.*)\]", stripped)
                            if m:
                                current_rule["destinations"] = [d.strip() for d in m.group(1).split(",") if d.strip()]
                        elif stripped.startswith("ports:"):
                            m = re.search(r"\[(.*)\]", stripped)
                            if m:
                                current_rule["ports"] = [p.strip().strip('"\'') for p in m.group(1).split(",") if p.strip()]

            elif current_section == "setup_keys":
                if stripped.startswith("- name:"):
                    name = stripped.split(":", 1)[1].strip().strip('\"\'')
                    current_item = {"name": name}
                    result["setup_keys"].append(current_item)
                elif current_item:
                    if stripped.startswith("type:"):
                        current_item["type"] = stripped.split(":", 1)[1].strip()
                    elif stripped.startswith("expires_in_days:"):
                        current_item["expires_in_days"] = int(stripped.split(":", 1)[1].strip())
                    elif stripped.startswith("usage_limit:"):
                        current_item["usage_limit"] = int(stripped.split(":", 1)[1].strip())
                    elif stripped.startswith("auto_groups:"):
                        m = re.search(r"\[(.*)\]", stripped)
                        if m:
                            current_item["auto_groups"] = [g.strip() for g in m.group(1).split(",") if g.strip()]

            elif current_section == "dns_zones":
                if raw.startswith("  - name:"):
                    name = stripped.split(":", 1)[1].strip().strip('\"\'')
                    current_item = {"name": name, "records": []}
                    result["dns_zones"].append(current_item)
                elif current_item:
                    if raw.startswith("      - name:"):
                        rec_name = stripped.split(":", 1)[1].strip().strip('\"\'')
                        current_rule = {"name": rec_name}
                        current_item["records"].append(current_rule)
                    elif stripped.startswith("domain:"):
                        current_item["domain"] = stripped.split(":", 1)[1].strip().strip('\"\'')
                    elif stripped.startswith("enabled:"):
                        current_item["enabled"] = stripped.split(":", 1)[1].strip().lower() == "true"
                    elif stripped.startswith("distribution_groups:"):
                        m = re.search(r"\[(.*)\]", stripped)
                        if m:
                            current_item["distribution_groups"] = [g.strip() for g in m.group(1).split(",") if g.strip()]
                    elif current_rule:
                        if stripped.startswith("type:"):
                            current_rule["type"] = stripped.split(":", 1)[1].strip()
                        elif stripped.startswith("content:"):
                            current_rule["content"] = stripped.split(":", 1)[1].strip().strip('\"\'')
                        elif stripped.startswith("ttl:"):
                            current_rule["ttl"] = int(stripped.split(":", 1)[1].strip())

    return result

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

    # Identify and remove default "All" policy if present
    for p in existing:
        if p["name"].lower() in ["default", "all"]:
            print(f"  {YELLOW}⚠️  Detected default open policy '{p['name']}'. Deleting for Zero-Trust...{NC}")
            if not dry_run:
                api_request(base_url, f"/policies/{p['id']}", token, method="DELETE")

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


def sync_dns_zones(base_url, token, declared_zones, group_name_to_id, dry_run=True):
    """Synchronize internal split-DNS zones and their records."""
    print(f"\n{BLUE}--- 🌐 Synchronizing Internal DNS Zones ---{NC}")
    existing_zones = api_request(base_url, "/dns/zones", token)
    zone_map = {z["name"]: z for z in existing_zones}
    synced_records = 0

    for zone_cfg in declared_zones:
        name = zone_cfg["name"]
        domain = zone_cfg.get("domain", "brain.cs.ait.ac.th")
        dist_groups = [group_name_to_id[g] for g in zone_cfg.get("distribution_groups", []) if g in group_name_to_id]

        if name in zone_map:
            zone = zone_map[name]
            zone_id = zone["id"]
            print(f"  {GREEN}✔ DNS Zone exists:{NC} {name} ({domain})")
        else:
            print(f"  {YELLOW}+ Creating DNS Zone:{NC} {name} ({domain})")
            if not dry_run:
                payload = {
                    "name": name,
                    "domain": domain,
                    "enabled": zone_cfg.get("enabled", True),
                    "distribution_groups": dist_groups
                }
                zone = api_request(base_url, "/dns/zones", token, method="POST", data=payload)
                zone_id = zone["id"]
            else:
                zone_id = "dry-run-zone-id"

        existing_records = []
        if not dry_run and zone_id != "dry-run-zone-id":
            existing_records = api_request(base_url, f"/dns/zones/{zone_id}/records", token)
        rec_map = {r["name"]: r for r in existing_records}

        for rec in zone_cfg.get("records", []):
            rec_name = rec["name"]
            rec_type = rec.get("type", "A")
            content = rec["content"]
            ttl = rec.get("ttl", 300)

            if rec_name in rec_map:
                print(f"    {GREEN}✔ DNS Record exists:{NC} {rec_name} -> {content}")
            else:
                print(f"    {YELLOW}+ Adding DNS Record:{NC} {rec_name} -> {content}")
                if not dry_run and zone_id != "dry-run-zone-id":
                    rec_payload = {
                        "name": rec_name,
                        "type": rec_type,
                        "content": content,
                        "ttl": ttl
                    }
                    api_request(base_url, f"/dns/zones/{zone_id}/records", token, method="POST", data=rec_payload)
                    synced_records += 1
                else:
                    synced_records += 1

    return synced_records

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
    synced_keys = sync_setup_keys(args.api_url, token, declared_setup_keys, group_map, dry_run=not args.apply)

    # 4. Sync DNS Zones
    declared_dns_zones = network_spec.get("dns_zones", [])
    synced_dns = sync_dns_zones(args.api_url, token, declared_dns_zones, group_map, dry_run=not args.apply)

    print(f"\n{BLUE}{'=' * 65}{NC}")
    if not args.apply:
        print(f"{YELLOW}🔎 DRY-RUN COMPLETE: No changes were made to live NetBird.{NC}")
        print(f"To apply these changes, run:")
        print(f"  {BOLD}{sys.argv[0]} --apply{NC}\n")
    else:
        print(f"{GREEN}🎉 NETBIRD GITOPS SYNCHRONIZATION COMPLETE!{NC}")
        print(f"Groups created/checked: {len(declared_groups)}")
        print(f"Setup keys managed:     {len(declared_setup_keys)}")
        print(f"DNS records managed:    {synced_dns}")
        print(f"{BLUE}{'=' * 65}{NC}\n")

if __name__ == "__main__":
    main()
