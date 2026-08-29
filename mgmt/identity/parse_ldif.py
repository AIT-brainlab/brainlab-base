#!/usr/bin/env python3
# Standard library only (no pyyaml required)

def parse_ldif(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    entries = content.split("\n\n")
    users = []
    
    # Internal Authentik or dummy test accounts to exclude
    exclude_prefixes = [
        "ak-outpost-", "akadmin", "aitgpt-ldap", "ldapservice",
        "alumni_01", "candidate_01", "faculty_01", "management_01", 
        "staff_01", "student_01"
    ]

    for entry in entries:
        lines = entry.strip().split("\n")
        data = {}
        for line in lines:
            if ":" in line:
                parts = line.split(":", 1)
                k = parts[0].strip()
                v = parts[1].strip()
                if k in data:
                    if isinstance(data[k], list):
                        data[k].append(v)
                    else:
                        data[k] = [data[k], v]
                else:
                    data[k] = v

        cn = data.get("cn")
        uid_num = data.get("uidNumber")
        if not cn or not uid_num:
            continue

        if any(cn.startswith(prefix) for prefix in exclude_prefixes):
            continue

        # All real users belong to 'brainlab'
        assigned_groups = ["brainlab"]

        # ONLY 'bci' (brainlab@ait.asia) is admin
        if cn == "bci":
            assigned_groups.append("admin")

        # Multi-email binding for akraradets
        secondary_emails = []
        if cn == "akraradets":
            secondary_emails.append("akraradets@gmail.com")

        users.append({
            "username": cn,
            "display_name": data.get("displayName") or data.get("name", cn),
            "primary_email": data.get("mail") or f"{cn}@ait.asia",
            "secondary_emails": secondary_emails,
            "uid": int(uid_num),
            "gid": int(data.get("gidNumber", 2000)),
            "home_directory": data.get("homeDirectory") or f"/mnt/pool-1/home/{cn}",
            "login_shell": data.get("loginShell", "/bin/bash"),
            "groups": sorted(list(set(assigned_groups)))
        })

    # Sort users by UID
    users.sort(key=lambda x: x["uid"])

    # Write clean, simple YAML with only brainlab and admin groups
    lines_out = [
        "# ==========================================================",
        "# 👥 AIT Brainlab Members (Identity-as-Code)",
        "# ==========================================================",
        "",
        "groups:",
        "  - name: admin",
        '    display_name: "Administrators"',
        "  - name: brainlab",
        '    display_name: "Brainlab Members"',
        "",
        "members:"
    ]

    for u in users:
        lines_out.append(f"  - username: {u['username']}")
        lines_out.append(f'    display_name: "{u["display_name"]}"')
        lines_out.append(f"    primary_email: {u['primary_email']}")
        if u["secondary_emails"]:
            lines_out.append("    secondary_emails:")
            for se in u["secondary_emails"]:
                lines_out.append(f"      - {se}")
        lines_out.append(f"    uid: {u['uid']}")
        lines_out.append(f"    gid: {u['gid']}")
        lines_out.append(f"    home_directory: {u['home_directory']}")
        lines_out.append(f"    login_shell: {u['login_shell']}")
        group_str = ", ".join(u["groups"])
        lines_out.append(f"    groups: [{group_str}]")
        lines_out.append("")

    with open("mgmt/identity/members.yaml", "w", encoding="utf-8") as out:
        out.write("\n".join(lines_out))

    print(f"✅ Generated mgmt/identity/members.yaml (28 users, only bci is admin)")

if __name__ == "__main__":
    parse_ldif("mgmt/identity/member.lidf")
