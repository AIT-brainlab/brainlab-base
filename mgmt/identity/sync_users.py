#!/usr/bin/env python3
"""
AIT Brainlab Identity Synchronization Tool (GitOps)
Synchronizes mgmt/identity/members.yaml to LLDAP via GraphQL API.
"""

import sys
import os
import json
import ssl
import subprocess
import urllib.request
import urllib.error
import argparse
import re

LLDAP_DEFAULT_URL = "https://ldap.brain.cs.ait.ac.th"
PROJECT_ID = "ait-brainlab-mgmt"

def get_admin_password():
    if os.environ.get("LLDAP_ADMIN_PASSWORD"):
        return os.environ["LLDAP_ADMIN_PASSWORD"]
    try:
        cmd = f"gcloud secrets versions access latest --secret=lldap-admin-password --project={PROJECT_ID}"
        pw = subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
        return pw
    except Exception as e:
        print(f"❌ Failed to fetch lldap-admin-password from GCP Secret Manager: {e}", file=sys.stderr)
        sys.exit(1)

def parse_simple_yaml(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    groups = []
    members = []
    
    current_section = None
    current_item = None
    in_secondary_emails = False

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if stripped == "groups:":
            current_section = "groups"
            continue
        elif stripped == "members:":
            current_section = "members"
            continue

        if current_section == "groups":
            if stripped.startswith("- name:"):
                name = stripped.split(":", 1)[1].strip()
                current_item = {"name": name}
                groups.append(current_item)
            elif stripped.startswith("display_name:") and current_item:
                current_item["display_name"] = stripped.split(":", 1)[1].strip().strip('"')

        elif current_section == "members":
            if stripped.startswith("- username:"):
                username = stripped.split(":", 1)[1].strip()
                current_item = {
                    "username": username,
                    "secondary_emails": [],
                    "groups": []
                }
                members.append(current_item)
                in_secondary_emails = False
            elif current_item:
                if stripped.startswith("display_name:"):
                    current_item["display_name"] = stripped.split(":", 1)[1].strip().strip('"')
                    in_secondary_emails = False
                elif stripped.startswith("primary_email:"):
                    current_item["primary_email"] = stripped.split(":", 1)[1].strip()
                    in_secondary_emails = False
                elif stripped.startswith("uid:"):
                    current_item["uid"] = int(stripped.split(":", 1)[1].strip())
                    in_secondary_emails = False
                elif stripped.startswith("gid:"):
                    current_item["gid"] = int(stripped.split(":", 1)[1].strip())
                    in_secondary_emails = False
                elif stripped.startswith("home_directory:"):
                    current_item["home_directory"] = stripped.split(":", 1)[1].strip()
                    in_secondary_emails = False
                elif stripped.startswith("login_shell:"):
                    current_item["login_shell"] = stripped.split(":", 1)[1].strip()
                    in_secondary_emails = False
                elif stripped.startswith("groups:"):
                    m = re.search(r"\[(.*)\]", stripped)
                    if m:
                        current_item["groups"] = [g.strip() for g in m.group(1).split(",") if g.strip()]
                    in_secondary_emails = False
                elif stripped.startswith("secondary_emails:"):
                    in_secondary_emails = True
                elif in_secondary_emails and stripped.startswith("- "):
                    email = stripped[2:].strip()
                    current_item["secondary_emails"].append(email)

    return {"groups": groups, "members": members}

class LLDAPClient:
    def __init__(self, base_url, password):
        self.base_url = base_url.rstrip("/")
        self.password = password
        self.token = None
        self.ctx = ssl.create_default_context()
        self.ctx.check_hostname = False
        self.ctx.verify_mode = ssl.CERT_NONE

    def login(self):
        login_url = f"{self.base_url}/auth/simple/login"
        req = urllib.request.Request(
            login_url,
            data=json.dumps({"username": "admin", "password": self.password}).encode(),
            headers={"Content-Type": "application/json"}
        )
        try:
            res = urllib.request.urlopen(req, context=self.ctx)
            data = json.loads(res.read().decode())
            self.token = data["token"]
        except urllib.error.HTTPError as e:
            print(f"❌ Authentication failed (HTTP {e.code}): {e.read().decode()}", file=sys.stderr)
            sys.exit(1)

    def gql(self, query):
        if not self.token:
            self.login()
        req = urllib.request.Request(
            f"{self.base_url}/api/graphql",
            data=json.dumps({"query": query}).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.token}"
            }
        )
        try:
            res = urllib.request.urlopen(req, context=self.ctx)
            result = json.loads(res.read().decode())
            if "errors" in result:
                raise RuntimeError(f"GraphQL Errors: {result['errors']}")
            return result.get("data", {})
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"GraphQL HTTP {e.code}: {e.read().decode()}")

    def ensure_custom_attributes(self, dry_run=False):
        print("🔍 Checking custom user attributes schema in LLDAP...")
        data = self.gql("{ schema { userSchema { attributes { name } } } }")
        existing_attrs = {a["name"] for a in data.get("schema", {}).get("userSchema", {}).get("attributes", [])}

        required_attrs = [
            ("uidnumber", "INTEGER", False),
            ("gidnumber", "INTEGER", False),
            ("homedirectory", "STRING", False),
            ("loginshell", "STRING", False),
            ("secondary-emails", "STRING", True)
        ]

        for name, attr_type, is_list in required_attrs:
            if name not in existing_attrs:
                print(f"  ➕ Adding custom attribute '{name}' ({attr_type}, isList={is_list})...")
                if not dry_run:
                    list_str = "true" if is_list else "false"
                    mutation = f"""
                    mutation {{
                      addUserAttribute(name: "{name}", attributeType: {attr_type}, isList: {list_str}, isVisible: true, isEditable: true) {{
                        ok
                      }}
                    }}
                    """
                    self.gql(mutation)
            else:
                print(f"  ✓ Attribute '{name}' already present.")

    def get_existing_directory(self):
        data = self.gql("""
        {
          users {
            id
            email
            displayName
            groups { id displayName }
            attributes { name value }
          }
          groups {
            id
            displayName
          }
        }
        """)
        users = {u["id"]: u for u in data.get("users", [])}
        groups = {g["displayName"]: g for g in data.get("groups", [])}
        return users, groups

    def sync(self, desired_data, dry_run=False):
        self.ensure_custom_attributes(dry_run)
        existing_users, existing_groups = self.get_existing_directory()

        print("\n👥 Synchronizing Groups...")
        for g in desired_data["groups"]:
            name = g["name"]
            if name not in existing_groups:
                print(f"  ➕ Creating group '{name}'...")
                if not dry_run:
                    self.gql(f'mutation {{ createGroup(name: "{name}") {{ id }} }}')
            else:
                print(f"  ✓ Group '{name}' exists (ID: {existing_groups[name]['id']}).")

        # Refresh groups lookup
        if not dry_run:
            _, existing_groups = self.get_existing_directory()

        print("\n👤 Synchronizing Members...")
        created_count = 0
        updated_count = 0

        for member in desired_data["members"]:
            username = member["username"]
            email = member["primary_email"]
            display_name = member["display_name"]
            uid = member["uid"]
            gid = member["gid"]
            home = member["home_directory"]
            shell = member["login_shell"]
            groups = member["groups"]
            secondary = member.get("secondary_emails", [])

            user_exists = username in existing_users

            if not user_exists:
                print(f"  ➕ Creating member '{username}' (UID: {uid}, {email})...")
                if not dry_run:
                    create_m = f"""
                    mutation {{
                      createUser(user: {{
                        id: "{username}"
                        email: "{email}"
                        displayName: "{display_name}"
                      }}) {{
                        id
                      }}
                    }}
                    """
                    self.gql(create_m)
                created_count += 1
            else:
                print(f"  🔄 Updating member '{username}' (UID: {uid})...")
                updated_count += 1

            if not dry_run:
                # Update attributes
                attrs = [
                    f'{{ name: "uidnumber", value: ["{uid}"] }}',
                    f'{{ name: "gidnumber", value: ["{gid}"] }}',
                    f'{{ name: "homedirectory", value: ["{home}"] }}',
                    f'{{ name: "loginshell", value: ["{shell}"] }}'
                ]
                if secondary:
                    sec_vals = ", ".join([f'"{s}"' for s in secondary])
                    attrs.append(f'{{ name: "secondary-emails", value: [{sec_vals}] }}')

                attrs_str = ", ".join(attrs)
                update_m = f"""
                mutation {{
                  updateUser(user: {{
                    id: "{username}"
                    email: "{email}"
                    displayName: "{display_name}"
                    insertAttributes: [{attrs_str}]
                  }}) {{
                    ok
                  }}
                }}
                """
                self.gql(update_m)

                # Group memberships
                current_groups = set()
                if user_exists:
                    current_groups = {grp["displayName"] for grp in existing_users[username].get("groups", [])}

                for grp_name in groups:
                    if grp_name in existing_groups and grp_name not in current_groups:
                        grp_id = existing_groups[grp_name]["id"]
                        self.gql(f'mutation {{ addUserToGroup(userId: "{username}", groupId: {grp_id}) {{ ok }} }}')

        print("\n==========================================================")
        mode = "DRY-RUN (No changes applied)" if dry_run else "APPLIED SUCCESSFULLY"
        print(f"🎉 Identity Sync Summary ({mode}):")
        print(f"   Total Desired Members : {len(desired_data['members'])}")
        print(f"   Created Members       : {created_count}")
        print(f"   Updated Members       : {updated_count}")
        print("==========================================================")


def main():
    parser = argparse.ArgumentParser(description="Sync members.yaml to LLDAP via GraphQL")
    parser.add_argument("--file", default="mgmt/identity/members.yaml", help="Path to members.yaml")
    parser.add_argument("--url", default=LLDAP_DEFAULT_URL, help="LLDAP Base URL")
    parser.add_argument("--apply", action="store_true", help="Apply changes to LLDAP (default is dry-run)")
    args = parser.parse_args()

    print("==========================================================")
    print(f"👥 AIT Brainlab Identity GitOps Sync ({'APPLY' if args.apply else 'DRY RUN'})")
    print(f"   Target URL: {args.url}")
    print(f"   Source File: {args.file}")
    print("==========================================================")

    data = parse_simple_yaml(args.file)
    print(f"📖 Loaded {len(data['groups'])} groups and {len(data['members'])} members from {args.file}.")

    pw = get_admin_password()
    client = LLDAPClient(args.url, pw)
    client.login()
    print("✅ Authenticated successfully as admin to LLDAP.")

    client.sync(data, dry_run=not args.apply)

if __name__ == "__main__":
    main()
