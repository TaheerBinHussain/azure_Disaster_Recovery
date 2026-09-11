"""
Week 6 — Cloud Native AI on Azure
Bare-minimum FastAPI app to showcase:
  - Blue/Green deployments
  - Canary traffic splitting
  - Auto-scaling
  - Self-healing (health probes)
  - Disaster Recovery
"""

import os
import socket
import platform
from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(
    title="Azure Disaster Recovery Demo",
    description="Week 6 — Cloud Native AI | Azure Free Tier",
    version=os.getenv("APP_VERSION", "1.0.0"),
)

# ── Meta ──────────────────────────────────────────────────────────────────────
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
DEPLOYMENT_COLOR = os.getenv("DEPLOYMENT_COLOR", "blue")   # "blue" or "green"
REGION = os.getenv("REGION", "eastus")
START_TIME = datetime.now(timezone.utc)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, summary="Landing page")
async def root():
    """Styled landing page that shows deployment info."""
    color_hex = "#2563EB" if DEPLOYMENT_COLOR == "blue" else "#16A34A"
    uptime = (datetime.now(timezone.utc) - START_TIME).seconds
    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title>Azure DR Demo — {DEPLOYMENT_COLOR.upper()} Deployment</title>
      <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
          font-family: 'Segoe UI', sans-serif;
          background: #0f172a;
          color: #e2e8f0;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }}
        .card {{
          background: #1e293b;
          border: 1px solid {color_hex};
          border-radius: 16px;
          padding: 40px 50px;
          max-width: 600px;
          width: 90%;
          box-shadow: 0 0 40px {color_hex}44;
          text-align: center;
        }}
        .badge {{
          display: inline-block;
          background: {color_hex};
          color: white;
          padding: 6px 18px;
          border-radius: 99px;
          font-size: 13px;
          font-weight: 700;
          letter-spacing: 1px;
          text-transform: uppercase;
          margin-bottom: 24px;
        }}
        h1 {{ font-size: 28px; margin-bottom: 8px; }}
        .subtitle {{ color: #94a3b8; font-size: 14px; margin-bottom: 32px; }}
        .grid {{
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          text-align: left;
        }}
        .stat {{
          background: #0f172a;
          border-radius: 10px;
          padding: 14px 16px;
        }}
        .stat-label {{ color: #64748b; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; }}
        .stat-value {{ font-size: 16px; font-weight: 600; margin-top: 4px; color: {color_hex}; }}
        .endpoints {{ margin-top: 28px; text-align: left; }}
        .endpoints h3 {{ color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 12px; }}
        .ep {{ background: #0f172a; border-radius: 8px; padding: 8px 14px; margin-bottom: 8px; font-size: 13px; font-family: monospace; color: #7dd3fc; }}
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">🟦 {DEPLOYMENT_COLOR} deployment</span>
        <h1>Azure Disaster Recovery</h1>
        <p class="subtitle">Week 6 — Cloud Native AI | Free Tier</p>
        <div class="grid">
          <div class="stat">
            <div class="stat-label">Version</div>
            <div class="stat-value">v{APP_VERSION}</div>
          </div>
          <div class="stat">
            <div class="stat-label">Region</div>
            <div class="stat-value">{REGION}</div>
          </div>
          <div class="stat">
            <div class="stat-label">Host</div>
            <div class="stat-value">{socket.gethostname()[:14]}</div>
          </div>
          <div class="stat">
            <div class="stat-label">Uptime</div>
            <div class="stat-value">{uptime}s</div>
          </div>
        </div>
        <div class="endpoints">
          <h3>Available Endpoints</h3>
          <div class="ep">GET /health   → liveness probe</div>
          <div class="ep">GET /ready    → readiness probe</div>
          <div class="ep">GET /info     → deployment metadata</div>
          <div class="ep">GET /docs     → Swagger UI</div>
        </div>
      </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html)


@app.get("/health", summary="Liveness probe — Azure Container Apps uses this")
async def health():
    """
    Azure Container Apps pings this every 30s.
    If it returns non-200, the container is restarted automatically (self-healing).
    """
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": APP_VERSION,
        "deployment": DEPLOYMENT_COLOR,
    }


@app.get("/ready", summary="Readiness probe — only accept traffic when truly ready")
async def ready():
    """
    Readiness probe — Azure waits for this before routing traffic.
    Prevents sending traffic to a still-booting container.
    """
    return {
        "status": "ready",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/info", summary="Full deployment metadata")
async def info():
    """Returns full metadata about this running instance."""
    return {
        "app": "azure-disaster-recovery-demo",
        "version": APP_VERSION,
        "deployment_color": DEPLOYMENT_COLOR,
        "region": REGION,
        "hostname": socket.gethostname(),
        "platform": platform.system(),
        "python_version": platform.python_version(),
        "started_at": START_TIME.isoformat(),
        "uptime_seconds": (datetime.now(timezone.utc) - START_TIME).seconds,
        "azure_features_demo": [
            "Blue/Green deployments",
            "Canary traffic splitting",
            "Auto-scaling (scale to zero)",
            "Self-healing (liveness probes)",
            "Disaster Recovery (multi-region)",
            "Zero-downtime deployments",
            "GitHub Actions CI/CD",
            "Terraform IaC",
        ],
    }
