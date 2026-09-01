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

from datetime import datetime, timezone

class IdentityResolver:
    DEFAULT_URL = "https://raw.githubusercontent.com/AIT-brainlab/brainlab-base/main/mgmt/identity/members.yaml"

    def __init__(self, members_yaml_path: Optional[str] = None, members_yaml_url: Optional[str] = None):
        self.members_yaml_path = members_yaml_path or os.getenv("MEMBERS_YAML_PATH")
        self.members_yaml_url = members_yaml_url or os.getenv("MEMBERS_YAML_URL", self.DEFAULT_URL)
        self.email_to_username: Dict[str, str] = {}
        self.last_updated: Optional[datetime] = None
        self.load_members()

    def load_members(self) -> dict:
        """Loads members.yaml from GitHub raw URL (Single Source of Truth) or local filesystem fallback."""
        raw_content = None
        source_used = "none"

        # 1. Try fetching from URL first (Single Source of Truth)
        if self.members_yaml_url:
            try:
                import urllib.request
                req = urllib.request.Request(
                    self.members_yaml_url,
                    headers={"User-Agent": "AIT-Brainlab-WebPrint/1.0"}
                )
                with urllib.request.urlopen(req, timeout=10) as response:
                    if response.status == 200:
                        raw_content = response.read().decode("utf-8")
                        source_used = f"url ({self.members_yaml_url})"
                        logger.info(f"Successfully fetched members.yaml from {self.members_yaml_url}")
            except Exception as e:
                logger.warning(f"Could not fetch members.yaml from URL ({self.members_yaml_url}): {e}")

        # 2. Fallback to local file if URL fetch failed or not configured
        if not raw_content and self.members_yaml_path and os.path.exists(self.members_yaml_path):
            try:
                with open(self.members_yaml_path, "r", encoding="utf-8") as f:
                    raw_content = f.read()
                source_used = f"local file ({self.members_yaml_path})"
                logger.info(f"Loaded members.yaml from local file: {self.members_yaml_path}")
            except Exception as e:
                logger.error(f"Error reading local members.yaml ({self.members_yaml_path}): {e}")

        # 3. Fallback to relative local repo path if running in development
        if not raw_content:
            dev_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../mgmt/identity/members.yaml"))
            if os.path.exists(dev_path):
                try:
                    with open(dev_path, "r", encoding="utf-8") as f:
                        raw_content = f.read()
                    source_used = f"dev path ({dev_path})"
                    logger.info(f"Loaded members.yaml from dev repo path: {dev_path}")
                except Exception as e:
                    logger.error(f"Error reading dev members.yaml: {e}")

        if not raw_content:
            if not self.email_to_username:
                logger.warning("members.yaml could not be loaded; relying on email prefix rules")
            return {
                "success": False,
                "count": len(self.email_to_username),
                "source": "fallback-prefix-only",
                "last_updated": self.last_updated.isoformat() if self.last_updated else None,
                "message": "Could not fetch members.yaml from URL or disk."
            }

        try:
            data = yaml.safe_load(raw_content) or {}
            members = data.get("members", [])
            new_mappings = {}
            for m in members:
                uname = m.get("username")
                if not uname:
                    continue
                p_email = m.get("primary_email")
                if p_email:
                    new_mappings[p_email.lower().strip()] = uname
                for s_email in m.get("secondary_emails", []):
                    if s_email:
                        new_mappings[s_email.lower().strip()] = uname

            self.email_to_username = new_mappings
            self.last_updated = datetime.now(timezone.utc)
            logger.info(f"Active identity mappings: {len(self.email_to_username)} user accounts from {source_used}")
            return {
                "success": True,
                "count": len(self.email_to_username),
                "source": source_used,
                "last_updated": self.last_updated.isoformat(),
                "message": f"Successfully loaded {len(self.email_to_username)} members."
            }
        except Exception as e:
            logger.error(f"Error parsing members.yaml: {e}")
            return {
                "success": False,
                "count": len(self.email_to_username),
                "source": source_used,
                "last_updated": self.last_updated.isoformat() if self.last_updated else None,
                "message": f"Parsing error: {e}"
            }

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
