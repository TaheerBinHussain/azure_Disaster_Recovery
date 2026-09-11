#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# canary.sh — Gradual canary rollout with auto-rollback
# Usage: ./scripts/canary.sh [image_tag]
# Stages: 0% → 10% → 25% → 50% → 75% → 100%
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP="week6-dr-app"
RG="week6-dr-rg"
IMAGE="ghcr.io/taheerbinhussain/azure_disaster_recovery"
TAG="${1:-latest}"

STAGES=(10 25 50 75 100)
WAIT_SECONDS=30   # Wait between stages

echo "╔══════════════════════════════════════════════╗"
echo "║       🐦  Canary Deployment Pipeline         ║"
echo "╚══════════════════════════════════════════════╝"
echo "  Image : $IMAGE:$TAG"
echo "  Stages: ${STAGES[*]}% (${WAIT_SECONDS}s between each)"
echo ""

# ── Deploy new revision with 0% traffic ───────────────────────
echo "📦 Deploying canary revision (0% traffic)..."
az containerapp update \
  --name "$APP" \
  --resource-group "$RG" \
  --image "$IMAGE:$TAG" \
  --revision-suffix "canary-$(date +%s)"

CANARY_REVISION=$(az containerapp revision list \
  --name "$APP" \
  --resource-group "$RG" \
  --query "[0].name" -o tsv)

echo "  ✅ Canary revision: $CANARY_REVISION"

# Get app URL
APP_URL=$(az containerapp show \
  --name "$APP" \
  --resource-group "$RG" \
  --query "properties.configuration.ingress.fqdn" -o tsv)

# ── Gradual traffic shift ─────────────────────────────────────
for PERCENT in "${STAGES[@]}"; do
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🔀 Stage: Shifting $PERCENT% traffic to canary..."

  az containerapp ingress traffic set \
    --name "$APP" \
    --resource-group "$RG" \
    --revision-weight "$CANARY_REVISION=$PERCENT"

  echo "  ⏳ Waiting ${WAIT_SECONDS}s for metrics..."
  sleep "$WAIT_SECONDS"

  # Health check at each stage
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "https://$APP_URL/health" || echo "000")

  echo "  🩺 Health check: HTTP $STATUS"

  if [ "$STATUS" != "200" ]; then
    echo ""
    echo "❌ CANARY FAILED at $PERCENT% (HTTP $STATUS)"
    echo "🔄 Auto-rollback: reverting canary to 0% traffic..."

    az containerapp ingress traffic set \
      --name "$APP" \
      --resource-group "$RG" \
      --revision-weight "$CANARY_REVISION=0"

    echo "✅ Rollback complete. Previous stable version is serving 100%."
    exit 1
  fi

  echo "  ✅ Stage $PERCENT% — HEALTHY"
done

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  🎉  Canary reached 100%! Deployment done.  ║"
echo "║  URL: https://$APP_URL                       ║"
echo "╚══════════════════════════════════════════════╝"
