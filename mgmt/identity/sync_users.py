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
SYSTEM_USERS = {"admin", "ldapservice"}
SYSTEM_GROUPS = {"lldap_admin", "lldap_password_manager", "lldap_strict_readonly"}

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

def strip_quotes(val: str) -> str:
    val = val.strip()
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        return val[1:-1].strip()
    return val

def strip_inline_comment(val: str) -> str:
    in_single = False
    in_double = False
    res = []
    for ch in val:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == '#' and not in_single and not in_double:
            break
        res.append(ch)
    return "".join(res).strip()

def clean_value(val: str) -> str:
    return strip_quotes(strip_inline_comment(val))

def parse_simple_yaml(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    groups = []
    members = []
    
    current_section = None
    current_item = None
    in_secondary_emails = False
    in_groups_list = False

    for line in lines:
        raw_stripped = line.strip()
        if not raw_stripped or raw_stripped.startswith("#"):
            continue

        stripped = strip_inline_comment(raw_stripped)
        if not stripped:
            continue

        if stripped == "groups:":
            current_section = "groups"
            current_item = None
            in_secondary_emails = False
            in_groups_list = False
            continue
        elif stripped == "members:":
            current_section = "members"
            current_item = None
            in_secondary_emails = False
            in_groups_list = False
            continue

        if current_section == "groups":
            if stripped.startswith("- name:"):
                name = clean_value(stripped.split(":", 1)[1])
                current_item = {"name": name}
                groups.append(current_item)
            elif stripped.startswith("display_name:") and current_item:
                current_item["display_name"] = clean_value(stripped.split(":", 1)[1])
            elif stripped.startswith("gid:") and current_item:
                try:
                    current_item["gid"] = int(clean_value(stripped.split(":", 1)[1]))
                except ValueError:
                    pass

        elif current_section == "members":
            if stripped.startswith("- username:"):
                username = clean_value(stripped.split(":", 1)[1])
                current_item = {
                    "username": username,
                    "secondary_emails": [],
                    "groups": []
                }
                members.append(current_item)
                in_secondary_emails = False
                in_groups_list = False
            elif current_item:
                if stripped.startswith("display_name:"):
                    current_item["display_name"] = clean_value(stripped.split(":", 1)[1])
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("primary_email:"):
                    current_item["primary_email"] = clean_value(stripped.split(":", 1)[1])
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("uid:"):
                    current_item["uid"] = int(clean_value(stripped.split(":", 1)[1]))
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("gid:"):
                    current_item["gid"] = int(clean_value(stripped.split(":", 1)[1]))
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("home_directory:"):
                    current_item["home_directory"] = clean_value(stripped.split(":", 1)[1])
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("login_shell:"):
                    current_item["login_shell"] = clean_value(stripped.split(":", 1)[1])
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("csim_account:"):
                    current_item["csim_account"] = clean_value(stripped.split(":", 1)[1])
                    in_secondary_emails = False
                    in_groups_list = False
                elif stripped.startswith("groups:"):
                    in_secondary_emails = False
                    m = re.search(r"\[(.*)\]", stripped)
                    if m:
                        current_item["groups"] = [clean_value(g) for g in m.group(1).split(",") if clean_value(g)]
                        in_groups_list = False
                    else:
                        in_groups_list = True
                elif stripped.startswith("secondary_emails:"):
                    in_groups_list = False
                    m = re.search(r"\[(.*)\]", stripped)
                    if m:
                        current_item["secondary_emails"] = [clean_value(e) for e in m.group(1).split(",") if clean_value(e)]
                        in_secondary_emails = False
                    else:
                        in_secondary_emails = True
                elif in_secondary_emails and stripped.startswith("- "):
                    email = clean_value(stripped[2:])
                    if email:
                        current_item["secondary_emails"].append(email)
                elif in_groups_list and stripped.startswith("- "):
                    grp = clean_value(stripped[2:])
                    if grp:
                        current_item["groups"].append(grp)

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

    def sync(self, desired_data, dry_run=False, prune=False):
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
        unchanged_count = 0

        desired_usernames = set()

        for member in desired_data["members"]:
            username = member["username"]
            email = member["primary_email"]
            display_name = member["display_name"]
            uid = member["uid"]
            gid = member["gid"]
            home = member["home_directory"]
            shell = member["login_shell"]
            desired_group_names = set(member["groups"])
            secondary = sorted(member.get("secondary_emails", []))

            desired_usernames.add(username)
            user_exists = username in existing_users

            if not user_exists:
                print(f"  ➕ [CREATE] Member '{username}' (UID: {uid}, {email})")
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

                    for grp_name in desired_group_names:
                        if grp_name in existing_groups:
                            grp_id = existing_groups[grp_name]["id"]
                            self.gql(f'mutation {{ addUserToGroup(userId: "{username}", groupId: {grp_id}) {{ ok }} }}')

                created_count += 1
                continue

            # -------------------------------------------------------------
            # Existing User: Check for updates and compute diffs
            # -------------------------------------------------------------
            cur_user = existing_users[username]
            cur_email = cur_user.get("email", "")
            cur_display_name = cur_user.get("displayName", "")
            cur_groups = {grp["displayName"] for grp in cur_user.get("groups", [])}
            cur_group_ids = {grp["displayName"]: grp["id"] for grp in cur_user.get("groups", [])}

            cur_attr_map = {a["name"]: a["value"] for a in cur_user.get("attributes", [])}
            cur_uid = cur_attr_map.get("uidnumber", [""])[0]
            cur_gid = cur_attr_map.get("gidnumber", [""])[0]
            cur_home = cur_attr_map.get("homedirectory", [""])[0]
            cur_shell = cur_attr_map.get("loginshell", [""])[0]
            cur_secondary = sorted(cur_attr_map.get("secondary-emails", []))

            # Differences
            diffs = []
            if cur_email != email:
                diffs.append(f"email: '{cur_email}' -> '{email}'")
            if cur_display_name != display_name:
                diffs.append(f"displayName: '{cur_display_name}' -> '{display_name}'")
            if cur_uid != str(uid):
                diffs.append(f"uidnumber: {cur_uid} -> {uid}")
            if cur_gid != str(gid):
                diffs.append(f"gidnumber: {cur_gid} -> {gid}")
            if cur_home != home:
                diffs.append(f"homedirectory: '{cur_home}' -> '{home}'")
            if cur_shell != shell:
                diffs.append(f"loginshell: '{cur_shell}' -> '{shell}'")
            if cur_secondary != secondary:
                diffs.append(f"secondary-emails: {cur_secondary} -> {secondary}")

            groups_to_add = desired_group_names - cur_groups
            groups_to_remove = (cur_groups - desired_group_names) - SYSTEM_GROUPS
            if groups_to_add:
                diffs.append(f"groups added: {list(groups_to_add)}")
            if groups_to_remove:
                diffs.append(f"groups removed: {list(groups_to_remove)}")

            if diffs:
                print(f"  🔄 [UPDATE] Member '{username}' (UID: {uid}):")
                for d in diffs:
                    print(f"     • {d}")

                if not dry_run:
                    insert_attrs = [
                        f'{{ name: "uidnumber", value: ["{uid}"] }}',
                        f'{{ name: "gidnumber", value: ["{gid}"] }}',
                        f'{{ name: "homedirectory", value: ["{home}"] }}',
                        f'{{ name: "loginshell", value: ["{shell}"] }}'
                    ]
                    remove_attrs = []

                    if secondary:
                        sec_vals = ", ".join([f'"{s}"' for s in secondary])
                        insert_attrs.append(f'{{ name: "secondary-emails", value: [{sec_vals}] }}')
                    elif "secondary-emails" in cur_attr_map:
                        remove_attrs.append('"secondary-emails"')

                    insert_attrs_str = ", ".join(insert_attrs)
                    remove_attrs_str = ", ".join(remove_attrs)

                    update_m = f"""
                    mutation {{
                      updateUser(user: {{
                        id: "{username}"
                        email: "{email}"
                        displayName: "{display_name}"
                        removeAttributes: [{remove_attrs_str}]
                        insertAttributes: [{insert_attrs_str}]
                      }}) {{
                        ok
                      }}
                    }}
                    """
                    self.gql(update_m)

                    for grp_name in groups_to_add:
                        if grp_name in existing_groups:
                            grp_id = existing_groups[grp_name]["id"]
                            self.gql(f'mutation {{ addUserToGroup(userId: "{username}", groupId: {grp_id}) {{ ok }} }}')

                    for grp_name in groups_to_remove:
                        grp_id = cur_group_ids[grp_name]
                        self.gql(f'mutation {{ removeUserFromGroup(userId: "{username}", groupId: {grp_id}) {{ ok }} }}')

                updated_count += 1
            else:
                unchanged_count += 1

        # Check for orphaned accounts in LLDAP
        orphaned_users = set(existing_users.keys()) - desired_usernames - SYSTEM_USERS
        if orphaned_users:
            print("\n⚠️ Orphaned accounts in LLDAP (not in members.yaml):")
            for u in sorted(orphaned_users):
                print(f"  • {u}")
                if prune and not dry_run:
                    print(f"    🗑 Deleting orphaned user '{u}'...")
                    self.gql(f'mutation {{ deleteUser(userId: "{u}") {{ ok }} }}')

        print("\n==========================================================")
        mode = "DRY-RUN (No changes applied)" if dry_run else "APPLIED SUCCESSFULLY"
        print(f"🎉 Identity Sync Summary ({mode}):")
        print(f"   Total Desired Members : {len(desired_data['members'])}")
        print(f"   Created Members       : {created_count}")
        print(f"   Updated Members       : {updated_count}")
        print(f"   Up-to-Date Members    : {unchanged_count}")
        if orphaned_users:
            print(f"   Orphaned Members      : {len(orphaned_users)}")
        print("==========================================================")


def main():
    parser = argparse.ArgumentParser(description="Sync members.yaml to LLDAP via GraphQL")
    parser.add_argument("--file", default="mgmt/identity/members.yaml", help="Path to members.yaml")
    parser.add_argument("--url", default=LLDAP_DEFAULT_URL, help="LLDAP Base URL")
    parser.add_argument("--apply", action="store_true", help="Apply changes to LLDAP (default is dry-run)")
    parser.add_argument("--prune", action="store_true", help="Delete orphaned accounts in LLDAP not present in members.yaml")
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

    client.sync(data, dry_run=not args.apply, prune=args.prune)

if __name__ == "__main__":
    main()

