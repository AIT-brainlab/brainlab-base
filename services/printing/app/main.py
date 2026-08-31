"""
AIT Brainlab - Web Print Service Portal
FastAPI backend with Google OAuth2 SSO and CSIM LPD spooler.
"""

import os
import shutil
import tempfile
import logging
from typing import Optional
from fastapi import FastAPI, Request, UploadFile, File, Form, Depends, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from authlib.integrations.starlette_client import OAuth

from .auth import IdentityResolver
from .lpd import LPDClient
from .pdf_utils import analyze_pdf, convert_pdf_to_postscript

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("web-print")

app = FastAPI(title="AIT Brainlab Web Print Portal", version="1.0.0")

# Security and Sessions
SESSION_SECRET = os.getenv("SESSION_SECRET_KEY", "brainlab-default-insecure-key-change-me")
app.add_middleware(SessionMiddleware, secret_key=SESSION_SECRET, max_age=86400 * 7)

# Mount Static & Templates
current_dir = os.path.dirname(os.path.abspath(__file__))
templates = Jinja2Templates(directory=os.path.join(current_dir, "templates"))
app.mount("/static", StaticFiles(directory=os.path.join(current_dir, "static")), name="static")

# Configuration
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "")
BASE_URL = os.getenv("BASE_URL", "https://print.brain.cs.ait.ac.th").rstrip("/")
PRINT_SERVER_HOST = os.getenv("PRINT_SERVER_HOST", "192.41.170.5")
PRINT_SERVER_PORT = int(os.getenv("PRINT_SERVER_PORT", "515"))
MEMBERS_YAML_PATH = os.getenv("MEMBERS_YAML_PATH", "/app/members.yaml")

# Services
identity_resolver = IdentityResolver(members_yaml_path=MEMBERS_YAML_PATH)
lpd_client = LPDClient(host=PRINT_SERVER_HOST, port=PRINT_SERVER_PORT)

# OAuth Setup
oauth = OAuth()
if GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET:
    oauth.register(
        name="google",
        client_id=GOOGLE_CLIENT_ID,
        client_secret=GOOGLE_CLIENT_SECRET,
        server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
        client_kwargs={"scope": "openid email profile"},
    )


def get_current_user(request: Request) -> Optional[dict]:
    user = request.session.get("user")
    return user


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "web-print"}


@app.get("/login")
async def login(request: Request):
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        # Development mode bypass
        request.session["user"] = {
            "email": "st121413@ait.asia",
            "name": "Dev User",
            "username": "st121413"
        }
        return RedirectResponse(url="/")
    redirect_uri = f"{BASE_URL}/oauth2/callback"
    return await oauth.google.authorize_redirect(request, redirect_uri)


@app.get("/oauth2/callback")
async def auth_callback(request: Request):
    try:
        token = await oauth.google.authorize_access_token(request)
    except Exception as e:
        logger.error(f"OAuth token error: {e}")
        return RedirectResponse(url="/?error=oauth_failed")

    user_info = token.get("userinfo")
    if not user_info:
        return RedirectResponse(url="/?error=no_userinfo")

    email = user_info.get("email", "").lower().strip()
    if not identity_resolver.is_authorized(email):
        logger.warning(f"Unauthorized login attempt: {email}")
        return RedirectResponse(url="/?error=unauthorized_domain")

    username = identity_resolver.resolve_username(email)
    request.session["user"] = {
        "email": email,
        "name": user_info.get("name", username),
        "picture": user_info.get("picture", ""),
        "username": username
    }
    logger.info(f"User logged in: {email} -> CSIM account '{username}'")
    return RedirectResponse(url="/")


@app.get("/logout")
def logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/")


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    user = get_current_user(request)
    error = request.query_params.get("error")
    return templates.TemplateResponse(
        "index.html",
        {"request": request, "user": user, "error": error}
    )


@app.get("/api/queue-status")
def queue_status(queue: str = "ricoh"):
    try:
        status_text = lpd_client.check_queue(queue, long_format=True)
        return {"queue": queue, "status": status_text or "Idle / No active jobs"}
    except Exception as e:
        return {"queue": queue, "status": f"Unavailable: {e}"}


@app.post("/api/print")
async def submit_print_job(
    request: Request,
    file: UploadFile = File(...),
    printer: str = Form("ricoh"),
    color_mode: str = Form("monochrome"),
    duplex: str = Form("two-sided-long-edge"),
    copies: int = Form(1),
    page_range: Optional[str] = Form(None),
    color_confirmed: bool = Form(False),
):
    user = get_current_user(request)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required. Please sign in.")

    # Guardrail: Color printing confirmation
    if color_mode == "color" and not color_confirmed:
        raise HTTPException(
            status_code=400,
            detail="Color confirmation required. Color prints consume 10x printing quota."
        )

    # Queue selection: Ricoh (B&W or Color) vs HP LaserJet Magnum
    if printer == "magnum":
        target_queue = "magnum"
        actual_color = "monochrome"
    else:
        target_queue = "ricoh-colour" if color_mode == "color" else "ricoh"
        actual_color = color_mode

    # Validate file extension
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF documents (.pdf) are supported.")

    username = user["username"]

    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp_pdf:
        tmp_pdf_path = tmp_pdf.name
        shutil.copyfileobj(file.file, tmp_pdf)

    try:
        total_pages, is_valid = analyze_pdf(tmp_pdf_path)
        if not is_valid or total_pages <= 0:
            raise HTTPException(status_code=400, detail="Uploaded file is corrupted or invalid PDF.")

        # Parse page ranges if provided (e.g. "1-3")
        f_page, l_page = None, None
        if page_range and "-" in page_range:
            parts = page_range.split("-")
            try:
                f_page = int(parts[0].strip())
                l_page = int(parts[1].strip())
            except ValueError:
                pass

        logger.info(f"Processing PDF '{file.filename}' ({total_pages} pages) for {username} on {target_queue}")

        # Convert PDF to PostScript with duplex/color injection
        ps_payload = convert_pdf_to_postscript(
            tmp_pdf_path,
            duplex=duplex,
            color_mode=actual_color,
            first_page=f_page,
            last_page=l_page
        )

        # Dispatch copies
        job_ids = []
        for i in range(max(1, min(copies, 20))):
            job_id = lpd_client.submit_job(
                queue=target_queue,
                user=username,
                job_title=file.filename.replace(" ", "_"),
                payload=ps_payload,
                is_postscript=True
            )
            job_ids.append(job_id)

        quota_multiplier = 10 if actual_color == "color" else 1
        effective_pages = (l_page - f_page + 1 if (f_page and l_page) else total_pages) * copies

        return {
            "success": True,
            "jobs": job_ids,
            "printer": printer,
            "queue": target_queue,
            "color_mode": actual_color,
            "duplex": duplex,
            "copies": copies,
            "total_pages": total_pages,
            "charged_pages_estimate": effective_pages * quota_multiplier,
            "message": f"Submitted to {target_queue} successfully for CSIM account {username}!"
        }

    except Exception as e:
        logger.error(f"Failed to submit print job: {e}")
        raise HTTPException(status_code=500, detail=f"Spooler error: {str(e)}")
    finally:
        if os.path.exists(tmp_pdf_path):
            os.remove(tmp_pdf_path)
