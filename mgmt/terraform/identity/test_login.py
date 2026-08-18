#!/usr/bin/env python3
"""
==========================================================
🔍 AIT Brainlab - Interactive LLDAP Authentication Tester
==========================================================
Usage: python3 test_login.py
"""

import sys
import getpass
import json
import ssl
import subprocess
import urllib.request
import urllib.error

# Ignore SSL verification for staging/self-signed cert testing
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

DEFAULT_URL = "https://authen2.brain.cs.ait.ac.th"

GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"

def print_banner():
    print(f"\n{BLUE}{'=' * 65}{NC}")
    print(f"{BOLD}🔐 AIT Brainlab - Interactive LLDAP Login & Directory Tester{NC}")
    print(f"{BLUE}{'=' * 65}{NC}")
    print(f"{YELLOW}ℹ️  Architecture Note: Human accounts authenticate via Google OAuth2.{NC}")
    print(f"{YELLOW}   LLDAP stores no passwords for humans. Administrative bind user is 'admin'.{NC}")
    print(f"{BLUE}{'=' * 65}{NC}\n")

def get_secret_password():
    try:
        cmd = ["gcloud", "secrets", "versions", "access", "latest", "--secret=lldap-admin-password", "--project=ait-brainlab-mgmt"]
        pw = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
        return pw
    except Exception:
        return None

def login(endpoint, username, password):
    login_url = f"{endpoint}/auth/simple/login"
    payload = json.dumps({"username": username, "password": password}).encode("utf-8")
    
    req = urllib.request.Request(
        login_url,
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        response = urllib.request.urlopen(req, context=ctx, timeout=10)
        res_data = json.loads(response.read().decode("utf-8"))
        return res_data.get("token")
    except urllib.error.HTTPError as e:
        if e.code in (400, 401, 403):
            return None
        print(f"{RED}❌ Server HTTP Error: {e.code} - {e.reason}{NC}")
        return None
    except Exception as e:
        print(f"{RED}❌ Connection Error: {e}{NC}")
        return None

def query_all_users(endpoint, token):
    graphql_url = f"{endpoint}/api/graphql"
    query = """
    {
      users {
        id
        email
        displayName
        firstName
        lastName
        groups {
          displayName
        }
        attributes {
          name
          value
        }
      }
    }
    """
    req = urllib.request.Request(
        graphql_url,
        data=json.dumps({"query": query}).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    )
    try:
        response = urllib.request.urlopen(req, context=ctx, timeout=10)
        res_data = json.loads(response.read().decode("utf-8"))
        return res_data.get("data", {}).get("users", [])
    except Exception as e:
        print(f"{YELLOW}⚠️ Error querying users: {e}{NC}")
        return []

def query_user_info(endpoint, token, username):
    graphql_url = f"{endpoint}/api/graphql"
    query = f"""
    {{
      user(userId: "{username}") {{
        id
        email
        displayName
        firstName
        lastName
        groups {{
          displayName
        }}
        attributes {{
          name
          value
        }}
      }}
    }}
    """
    
    req = urllib.request.Request(
        graphql_url,
        data=json.dumps({"query": query}).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
    )
    
    try:
        response = urllib.request.urlopen(req, context=ctx, timeout=10)
        res_data = json.loads(response.read().decode("utf-8"))
        return res_data.get("data", {}).get("user")
    except Exception as e:
        print(f"{YELLOW}⚠️ Could not query user '{username}': {e}{NC}")
        return None

def print_user_card(user_info):
    first = user_info.get("firstName") or ""
    last = user_info.get("lastName") or ""
    full_name = f"{first} {last}".strip()
    disp_name = user_info.get("displayName") or full_name or "N/A"
    email_addr = user_info.get("email") or "N/A"

    print(f"\n{BOLD}📋 Identity & POSIX Resolution for '{user_info.get('id')}':{NC}")
    print(f"{'-' * 55}")
    print(f"  • {BOLD}Username:{NC}       {user_info.get('id')}")
    print(f"  • {BOLD}Email:{NC}          {email_addr}")
    print(f"  • {BOLD}Display Name:{NC}   {disp_name}")
    
    # Attributes
    attrs = {a["name"].lower(): a["value"][0] if a.get("value") else "" for a in user_info.get("attributes", [])}
    print(f"  • {BOLD}POSIX UID:{NC}      {attrs.get('uidnumber', 'N/A')}")
    print(f"  • {BOLD}POSIX GID:{NC}      {attrs.get('gidnumber', 'N/A')}")
    print(f"  • {BOLD}Home Path:{NC}      {attrs.get('homedirectory', 'N/A')}")
    print(f"  • {BOLD}Login Shell:{NC}    {attrs.get('loginshell', 'N/A')}")
    
    # Groups
    groups = [g.get("displayName") for g in user_info.get("groups", [])]
    print(f"  • {BOLD}Group Memberships:{NC} {', '.join(groups) if groups else 'None'}")
    print(f"{'-' * 55}\n")

def main():
    print_banner()
    
    # 1. Prompt for server endpoint
    endpoint = input(f"{CYAN}Enter LLDAP Endpoint [{DEFAULT_URL}]: {NC}").strip()
    if not endpoint:
        endpoint = DEFAULT_URL
    if not endpoint.startswith("http"):
        endpoint = f"https://{endpoint}"
    
    # 2. Prompt for username & password
    username = input(f"{CYAN}Username [default: admin]: {NC}").strip()
    if not username:
        username = "admin"
        
    secret_pw = get_secret_password() if username == "admin" else None
    
    if secret_pw:
        use_secret = input(f"{CYAN}Use admin password from GCP Secret Manager? (Y/n): {NC}").strip().lower()
        if use_secret in ("", "y", "yes"):
            password = secret_pw
        else:
            password = getpass.getpass(f"{CYAN}Password: {NC}")
    else:
        password = getpass.getpass(f"{CYAN}Password: {NC}")
        
    if not password:
        print(f"{RED}Error: Password cannot be empty.{NC}")
        sys.exit(1)
    
    print(f"\n{BLUE}Connecting to {endpoint} as '{username}'...{NC}")
    
    # 3. Perform Authentication
    token = login(endpoint, username, password)
    
    if not token:
        print(f"\n{RED}❌ AUTHENTICATION FAILED: Invalid username or password.{NC}")
        if username != "admin":
            print(f"{YELLOW}💡 Note: '{username}' has no password in LLDAP because humans log in via Google OAuth2.{NC}")
            print(f"{YELLOW}   To test directory lookups, log in as 'admin'.{NC}\n")
        sys.exit(1)
        
    print(f"\n{GREEN}✅ AUTHENTICATION SUCCESSFUL!{NC}")
    print(f"{GREEN}🔑 JWT Session Token Issued: {token[:20]}...{token[-10:]}{NC}\n")
    
    # 4. Display all managed users
    users = query_all_users(endpoint, token)
    print(f"{BOLD}👥 Active Directory Accounts ({len(users)} found):{NC}")
    print(f"{'USERNAME':<15} {'EMAIL':<28} {'UID':<8} {'GID':<8} {'GROUPS'}")
    print("=" * 80)
    for u in users:
        attrs = {a["name"].lower(): a["value"][0] if a.get("value") else "" for a in u.get("attributes", [])}
        groups = ", ".join([g["displayName"] for g in u.get("groups", [])])
        print(f"{u['id']:<15} {u.get('email', '-'):<28} {attrs.get('uidnumber', '-'):<8} {attrs.get('gidnumber', '-'):<8} {groups}")
    print("=" * 80)

    # 5. Interactive User Lookup Loop
    while True:
        target = input(f"\n{CYAN}Enter username to inspect (or press Enter to exit): {NC}").strip()
        if not target:
            break
        u_info = query_user_info(endpoint, token, target)
        if u_info:
            print_user_card(u_info)
        else:
            print(f"{RED}❌ User '{target}' not found in LLDAP directory.{NC}")

    print(f"\n{GREEN}Done! Identity plane is fully operational.{NC}\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
        sys.exit(0)
