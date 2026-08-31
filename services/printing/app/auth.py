"""
AIT Brainlab - Authentication & CSIM Identity Resolver
Handles Google OAuth2 SSO and resolves user email to CSIM student username.
"""

import os
import re
import yaml
import logging
from typing import Optional, Dict

logger = logging.getLogger("web-print.auth")

class IdentityResolver:
    def __init__(self, members_yaml_path: str = "/app/members.yaml"):
        self.members_yaml_path = members_yaml_path
        self.email_to_username: Dict[str, str] = {}
        self.load_members()

    def load_members(self):
        """Loads members.yaml to map alumni personal emails to their persistent student ID / username."""
        if not os.path.exists(self.members_yaml_path):
            # Fallback to local repo path if running locally
            local_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../mgmt/identity/members.yaml"))
            if os.path.exists(local_path):
                self.members_yaml_path = local_path
            else:
                logger.warning(f"members.yaml not found at {self.members_yaml_path}; relying on email prefix")
                return

        try:
            with open(self.members_yaml_path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f) or {}

            members = data.get("members", [])
            for m in members:
                uname = m.get("username")
                if not uname:
                    continue
                p_email = m.get("primary_email")
                if p_email:
                    self.email_to_username[p_email.lower().strip()] = uname
                for s_email in m.get("secondary_emails", []):
                    if s_email:
                        self.email_to_username[s_email.lower().strip()] = uname
            logger.info(f"Loaded {len(self.email_to_username)} email-to-username identity mappings")
        except Exception as e:
            logger.error(f"Error loading members.yaml: {e}")

    def resolve_username(self, email: str) -> str:
        """
        Extracts student ID / username for CSIM quota accounting:
        1. Checks members.yaml (e.g. personal gmail -> st121413).
        2. If institutional (@ait.asia or @ait.ac.th), extracts local part (st121413@ait.asia -> st121413).
        3. Fallback: sanitize email prefix.
        """
        clean_email = email.lower().strip()
        if clean_email in self.email_to_username:
            return self.email_to_username[clean_email]

        # Check standard AIT patterns (e.g. st121413, akraradets)
        match = re.match(r"^([a-zA-Z0-9_\.\-]+)@(ait\.asia|ait\.ac\.th)$", clean_email)
        if match:
            return match.group(1)

        # Fallback: sanitized prefix
        return clean_email.split("@")[0].replace(".", "_")

    def is_authorized(self, email: str) -> bool:
        """Validates if user belongs to AIT domain or is registered in members.yaml."""
        clean_email = email.lower().strip()
        if clean_email in self.email_to_username:
            return True
        if clean_email.endswith("@ait.asia") or clean_email.endswith("@ait.ac.th"):
            return True
        return False
