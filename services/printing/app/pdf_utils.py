"""
AIT Brainlab - PDF and PostScript Utility Engine
Handles page counting, slicing, and conversion with PostScript Duplex injection.
"""

import os
import subprocess
import tempfile
from typing import Tuple, Optional
import pypdf

def analyze_pdf(file_path: str) -> Tuple[int, bool]:
    """Inspect PDF and return (total_page_count, is_valid)."""
    try:
        reader = pypdf.PdfReader(file_path)
        return len(reader.pages), True
    except Exception:
        return 0, False

def convert_pdf_to_postscript(
    pdf_path: str,
    duplex: str = "two-sided-long-edge",
    color_mode: str = "monochrome",
    first_page: Optional[int] = None,
    last_page: Optional[int] = None,
) -> bytes:
    """
    Converts PDF to PostScript using poppler pdftops.
    Injects device directives for duplex and monochrome/color.
    """
    with tempfile.NamedTemporaryFile(suffix=".ps", delete=False) as tmp_ps:
        tmp_ps_path = tmp_ps.name

    try:
        cmd = ["pdftops", "-paper", "A4"]

        # Page ranges
        if first_page and first_page > 0:
            cmd.extend(["-f", str(first_page)])
        if last_page and last_page >= (first_page or 1):
            cmd.extend(["-l", str(last_page)])

        # Duplex option
        if duplex in ("two-sided-long-edge", "two-sided-short-edge"):
            cmd.append("-duplex")

        # Color mode
        if color_mode == "monochrome":
            cmd.extend(["-level2", "-processcolorformat", "MONO8"])
        else:
            cmd.append("-level3")

        cmd.extend([pdf_path, tmp_ps_path])

        res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if res.returncode != 0:
            raise RuntimeError(f"pdftops conversion failed (exit code {res.returncode}): {res.stderr.strip()}")

        with open(tmp_ps_path, "rb") as f:
            ps_bytes = f.read()

        # Inject DSC / PostScript setpagedevice headers if not present
        if duplex == "two-sided-long-edge":
            ps_directive = b"\n%%BeginFeature: *Duplex DuplexNoTumble\n<< /Duplex true /Tumble false >> setpagedevice\n%%EndFeature\n"
        elif duplex == "two-sided-short-edge":
            ps_directive = b"\n%%BeginFeature: *Duplex DuplexTumble\n<< /Duplex true /Tumble true >> setpagedevice\n%%EndFeature\n"
        else:
            ps_directive = b"\n%%BeginFeature: *Duplex None\n<< /Duplex false >> setpagedevice\n%%EndFeature\n"

        # Inject directive right after %%EndComments or %%Page: 1 1
        if b"%%EndComments" in ps_bytes:
            parts = ps_bytes.split(b"%%EndComments", 1)
            ps_bytes = parts[0] + b"%%EndComments" + ps_directive + parts[1]

        return ps_bytes
    finally:
        if os.path.exists(tmp_ps_path):
            os.remove(tmp_ps_path)
