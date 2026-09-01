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

def parse_page_range(page_range_str: Optional[str], total_pages: int) -> Tuple[int, int]:
    """
    Parses various page range formats:
      - '2' -> (2, 2)  [Single page]
      - '2-5' -> (2, 5) [Range]
      - '3-' -> (3, total_pages) [From page 3 to end]
      - '-4' -> (1, 4) [From start to page 4]
      - None / '' -> (1, total_pages) [All pages]
    Safely clamps to [1, total_pages].
    """
    if not page_range_str or not page_range_str.strip():
        return 1, max(1, total_pages)

    s = page_range_str.strip()

    if "-" in s:
        parts = s.split("-", 1)
        start_str = parts[0].strip()
        end_str = parts[1].strip()

        try:
            start_page = int(start_str) if start_str else 1
        except ValueError:
            start_page = 1

        try:
            end_page = int(end_str) if end_str else total_pages
        except ValueError:
            end_page = total_pages

        start_page = max(1, min(start_page, total_pages))
        end_page = max(start_page, min(end_page, total_pages))
        return start_page, end_page

    try:
        page_num = int(s)
        page_num = max(1, min(page_num, total_pages))
        return page_num, page_num
    except ValueError:
        return 1, max(1, total_pages)

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
