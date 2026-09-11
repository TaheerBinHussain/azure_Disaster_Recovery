#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# blue_green.sh — Blue/Green deployment switcher
# Usage: ./scripts/blue_green.sh [blue|green] [image_tag]
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP="week6-dr-app"
RG="week6-dr-rg"
IMAGE="ghcr.io/taheerbinhussain/azure_disaster_recovery"

TARGET_COLOR="${1:-green}"   # Which color to promote to 100%
TAG="${2:-latest}"

echo "╔══════════════════════════════════════════════╗"
echo "║     🟦🟩  Blue/Green Deployment              ║"
echo "╚══════════════════════════════════════════════╝"
echo "  Target color : $TARGET_COLOR"
echo "  Image tag    : $TAG"
echo ""

# ── Step 1: Deploy new revision with color label ──────────────
echo "📦 Deploying new $TARGET_COLOR revision..."
az containerapp update \
  --name "$APP" \
  --resource-group "$RG" \
  --image "$IMAGE:$TAG" \
  --set-env-vars "DEPLOYMENT_COLOR=$TARGET_COLOR" \
  --revision-suffix "$TARGET_COLOR-$(date +%s)"

NEW_REVISION=$(az containerapp revision list \
  --name "$APP" \
  --resource-group "$RG" \
  --query "[0].name" -o tsv)
echo "  ✅ New revision: $NEW_REVISION"

# ── Step 2: Send 10% traffic to new revision (canary check) ───
echo ""
echo "🔀 Sending 10% traffic to $TARGET_COLOR (canary check)..."
az containerapp ingress traffic set \
  --name "$APP" \
  --resource-group "$RG" \
  --revision-weight "$NEW_REVISION=10"

sleep 20

# ── Step 3: Health check ──────────────────────────────────────
APP_URL=$(az containerapp show \
  --name "$APP" \
  --resource-group "$RG" \
  --query "properties.configuration.ingress.fqdn" -o tsv)

STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$APP_URL/health" || echo "000")

if [ "$STATUS" != "200" ]; then
  echo "❌ Health check failed (HTTP $STATUS). Reverting to 0% traffic..."
  az containerapp ingress traffic set \
    --name "$APP" \
    --resource-group "$RG" \
    --revision-weight "$NEW_REVISION=0"
  echo "✅ Reverted. Old revision still serving 100%."
  exit 1
fi

echo "  ✅ Health check passed (HTTP $STATUS)"

# ── Step 4: Promote to 100% ───────────────────────────────────
echo ""
echo "🎉 Promoting $TARGET_COLOR to 100% traffic..."
az containerapp ingress traffic set \
  --name "$APP" \
  --resource-group "$RG" \
  --revision-weight "$NEW_REVISION=100"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅  $TARGET_COLOR is now live at 100%!      ║"
echo "║  URL: https://$APP_URL                       ║"
echo "╚══════════════════════════════════════════════╝"
