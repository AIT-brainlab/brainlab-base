#!/usr/bin/env python3
"""
AIT Brainlab - LDIF to Terraform Identity Converter
Usage: python3 import_ldif_to_tf.py [path_to_exported_users.ldif]
"""

import sys
import re

def parse_ldif(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    entries = content.split("\n\n")
    users = {}

    for entry in entries:
        if not entry.strip():
            continue
        
        uid_match = re.search(r"^uid:\s*(.+)$", entry, re.MULTILINE)
        if not uid_match:
            continue
        
        uid = uid_match.group(1).strip()
        
        # Extract fields
        mail_match = re.search(r"^mail:\s*(.+)$", entry, re.MULTILINE)
        mail = mail_match.group(1).strip() if mail_match else f"{uid}@ait.asia"

        # Extract POSIX fields
        uid_num_match = re.search(r"^uidNumber:\s*(\d+)$", entry, re.MULTILINE)
        gid_num_match = re.search(r"^gidNumber:\s*(\d+)$", entry, re.MULTILINE)
        home_match = re.search(r"^homeDirectory:\s*(.+)$", entry, re.MULTILINE)
        shell_match = re.search(r"^loginShell:\s*(.+)$", entry, re.MULTILINE)

        uid_num = int(uid_num_match.group(1)) if uid_num_match else 10000
        gid_num = int(gid_num_match.group(1)) if gid_num_match else 10001
        home_dir = home_match.group(1).strip() if home_match else f"/mnt/HDD/home/{uid}"
        login_shell = shell_match.group(1).strip() if shell_match else "/bin/bash"

        first_match = re.search(r"^givenName:\s*(.+)$", entry, re.MULTILINE)
        last_match = re.search(r"^sn:\s*(.+)$", entry, re.MULTILINE)
        cn_match = re.search(r"^cn:\s*(.+)$", entry, re.MULTILINE)

        first_name = first_match.group(1).strip() if first_match else (cn_match.group(1).strip() if cn_match else uid)
        last_name = last_match.group(1).strip() if last_match else "Member"

        users[uid] = {
            "email": mail,
            "first_name": first_name,
            "last_name": last_name,
            "uid": uid_num,
            "gid": gid_num,
            "home": home_dir,
            "shell": login_shell,
            "groups": ["member", "student"]
        }

    return users

def generate_hcl(users):
    print("# Auto-generated from on-premise LDIF dump:")
    print("locals {")
    print("  users = {")
    for uid, data in sorted(users.items()):
        print(f'    "{uid}" = {{')
        print(f'      email      = "{data["email"]}"')
        print(f'      first_name = "{data["first_name"]}"')
        print(f'      last_name  = "{data["last_name"]}"')
        print(f'      uid        = {data["uid"]}')
        print(f'      gid        = {data["gid"]}')
        print(f'      home       = "{data["home"]}"')
        print(f'      shell      = "{data["shell"]}"')
        print(f'      groups     = {data["groups"]}')
        print("    },")
    print("  }")
    print("}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 import_ldif_to_tf.py <users.ldif>")
        sys.exit(1)
    
    parsed = parse_ldif(sys.argv[1])
    print(f"# Found {len(parsed)} users in LDIF file.\n")
    generate_hcl(parsed)
