"""
AIT Brainlab - Web Print Service Portal
FastAPI backend with Google OAuth2 SSO and CSIM LPD spooler.
"""

import os
import shutil
import tempfile
import logging
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
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

import asyncio
from contextlib import asynccontextmanager

# Configuration
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "")
BASE_URL = os.getenv("BASE_URL", "https://print.brain.cs.ait.ac.th").rstrip("/")
PRINT_SERVER_HOST = os.getenv("PRINT_SERVER_HOST", "192.41.170.5")
PRINT_SERVER_PORT = int(os.getenv("PRINT_SERVER_PORT", "515"))
MEMBERS_YAML_PATH = os.getenv("MEMBERS_YAML_PATH", "")
MEMBERS_YAML_URL = os.getenv("MEMBERS_YAML_URL", "https://raw.githubusercontent.com/AIT-brainlab/brainlab-base/main/mgmt/identity/members.yaml")
REFRESH_INTERVAL_SECONDS = int(os.getenv("MEMBERS_REFRESH_INTERVAL", 30 * 86400)) # Monthly (30 days)

# Services
identity_resolver = IdentityResolver(members_yaml_path=MEMBERS_YAML_PATH, members_yaml_url=MEMBERS_YAML_URL)
lpd_client = LPDClient(host=PRINT_SERVER_HOST, port=PRINT_SERVER_PORT)

from zoneinfo import ZoneInfo

# Timezone & Schedulers
BKK_TZ = ZoneInfo("Asia/Bangkok")

def seconds_until_next_month_1st() -> float:
    """Calculates exact seconds until 00:00:00 on the 1st day of the upcoming month (ICT)."""
    now = datetime.now(BKK_TZ)
    if now.month == 12:
        next_month = 1
        next_year = now.year + 1
    else:
        next_month = now.month + 1
        next_year = now.year
    
    target = datetime(next_year, next_month, 1, 0, 0, 0, tzinfo=BKK_TZ)
    diff = (target - now).total_seconds()
    return max(diff, 60.0)

async def periodic_member_refresh():
    """Cron-like scheduler: auto-syncs members.yaml from GitHub on the 1st of every month at 00:00 ICT."""
    while True:
        try:
            wait_seconds = seconds_until_next_month_1st()
            days_left = wait_seconds / 86400.0
            logger.info(f"Directory auto-sync scheduled in {days_left:.1f} days (1st of upcoming month at 00:00 ICT)")
            await asyncio.sleep(wait_seconds)
            logger.info("Executing scheduled 1st-of-the-month directory sync from GitHub...")
            identity_resolver.load_members()
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Error during monthly member refresh: {e}")
            await asyncio.sleep(3600)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: spawn periodic background task
    task = asyncio.create_task(periodic_member_refresh())
    yield
    # Shutdown: cancel task
    task.cancel()

app = FastAPI(title="AIT Brainlab Web Print Portal", version="1.0.0", lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=SESSION_SECRET, max_age=86400 * 7)
app.mount("/static", StaticFiles(directory=os.path.join(current_dir, "static")), name="static")

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
    return {
        "status": "ok",
        "service": "web-print",
        "members_loaded": len(identity_resolver.email_to_username),
        "last_updated": identity_resolver.last_updated.isoformat() if identity_resolver.last_updated else None
    }


@app.post("/api/members/refresh")
@app.get("/api/members/refresh")
def refresh_members():
    """Manually triggers directory reload from GitHub raw URL."""
    result = identity_resolver.load_members()
    return result


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
    csim_account = identity_resolver.resolve_csim_account(email)
    request.session["user"] = {
        "email": email,
        "name": user_info.get("name", username),
        "picture": user_info.get("picture", ""),
        "username": username,
        "csim_account": csim_account
    }
    logger.info(f"User logged in: {email} -> POSIX '{username}' / CSIM '{csim_account}'")
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
        request=request,
        name="index.html",
        context={"user": user, "error": error}
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
    print_account = user.get("csim_account")
    if not print_account:
        raise HTTPException(
            status_code=403,
            detail="No CSIM student ID linked to your account. Print quota cannot be attributed. Please contact an administrator to register your student ID in members.yaml."
        )

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

        logger.info(f"Processing PDF '{file.filename}' ({total_pages} pages) for {print_account} (posix: {username}) on {target_queue}")

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
                user=print_account,
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
