#!/usr/bin/env bash
# Reenvía los webhooks de prueba de Stripe al LMS local.
source "$(dirname "$0")/common.sh"
cd "$ROOT"
KEY="$(read_kv .env | sed -n 's/^COURSE_PAYMENTS_STRIPE_SECRET_KEY=//p' | tail -1)"
[ -n "$KEY" ] || { echo "Falta COURSE_PAYMENTS_STRIPE_SECRET_KEY en .env" >&2; exit 1; }
command -v stripe >/dev/null || { echo "Instala Stripe CLI: https://docs.stripe.com/stripe-cli" >&2; exit 1; }
echo "Copia el whsec_... que aparece abajo a COURSE_PAYMENTS_STRIPE_WEBHOOK_SECRET en .env y corre: make config"
exec stripe listen --api-key "$KEY" \
  --events checkout.session.completed,checkout.session.async_payment_succeeded,checkout.session.async_payment_failed,checkout.session.expired,charge.refunded \
  --forward-to "${STRIPE_FORWARD_URL:-http://local.openedx.io:8000/payments/webhook/stripe/}"
