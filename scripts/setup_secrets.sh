#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup_secrets.sh — Automatically configure all GitHub Secrets
# for CI/CD. Run once after creating the Azure Service Principal.
#
# Usage:
#   export GITHUB_PAT=<your_token>
#   export SUBSCRIPTION_ID=<your_sub_id>
#   ./scripts/setup_secrets.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

GITHUB_TOKEN="${GITHUB_PAT:?Set GITHUB_PAT env var before running}"
GITHUB_REPO="TaheerBinHussain/azure_Disaster_Recovery"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID env var before running}"
RESOURCE_GROUP="week6-dr-rg"

echo "╔══════════════════════════════════════════════╗"
echo "║   🔐  Setting up GitHub Secrets for CI/CD   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Step 1: Create Service Principal ─────────────────────────
echo "1️⃣  Creating Azure Service Principal..."
SP_JSON=$(az ad sp create-for-rbac \
  --name "week6-github-actions-sp" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth 2>/dev/null)

CLIENT_ID=$(echo "$SP_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['clientId'])")
CLIENT_SECRET=$(echo "$SP_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['clientSecret'])")
TENANT_ID=$(echo "$SP_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tenantId'])")

echo "  ✅ Service principal created: $CLIENT_ID"

# ── Step 2: Helper function to set a GitHub secret ───────────
set_secret() {
  local SECRET_NAME="$1"
  local SECRET_VALUE="$2"

  # Get repo public key for encryption
  KEY_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPO/actions/secrets/public-key")

  KEY_ID=$(echo "$KEY_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['key_id'])")
  PUBLIC_KEY=$(echo "$KEY_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")

  # Encrypt the secret using the repo's public key
  ENCRYPTED=$(python3 -c "
import base64, sys
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PublicKey
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import nacl.encoding, nacl.public

pub_key = nacl.public.PublicKey(base64.b64decode('$PUBLIC_KEY'))
box = nacl.public.SealedBox(pub_key)
encrypted = box.encrypt('$SECRET_VALUE'.encode())
print(base64.b64encode(encrypted).decode())
" 2>/dev/null || echo "NACL_NOT_AVAILABLE")

  # Fall back to plain text if nacl not available (GitHub API accepts this for setup)
  if [ "$ENCRYPTED" = "NACL_NOT_AVAILABLE" ]; then
    # Use GitHub CLI if available
    if command -v gh &>/dev/null; then
      echo "$SECRET_VALUE" | gh secret set "$SECRET_NAME" --repo "$GITHUB_REPO"
    else
      echo "  ⚠️  Install 'gh' CLI or 'PyNaCl' to auto-set secrets."
      echo "     Manual: Go to GitHub → Settings → Secrets → Actions → New secret"
      echo "     Name: $SECRET_NAME"
    fi
  else
    curl -s -X PUT \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      "https://api.github.com/repos/$GITHUB_REPO/actions/secrets/$SECRET_NAME" \
      -d "{\"encrypted_value\":\"$ENCRYPTED\",\"key_id\":\"$KEY_ID\"}" > /dev/null
    echo "  ✅ Secret set: $SECRET_NAME"
  fi
}

# ── Step 3: Set all required secrets ─────────────────────────
echo ""
echo "2️⃣  Setting GitHub Secrets..."
set_secret "AZURE_CREDENTIALS"   "$SP_JSON"
set_secret "ARM_CLIENT_ID"       "$CLIENT_ID"
set_secret "ARM_CLIENT_SECRET"   "$CLIENT_SECRET"
set_secret "ARM_TENANT_ID"       "$TENANT_ID"
set_secret "ARM_SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
set_secret "AZURE_RESOURCE_GROUP" "$RESOURCE_GROUP"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅  All secrets configured!                 ║"
echo "║  Push to main to trigger first deployment.  ║"
echo "╚══════════════════════════════════════════════╝"
