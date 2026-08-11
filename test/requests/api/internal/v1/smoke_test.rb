#!/usr/bin/env bash
set -euo pipefail

: "${AMID_API_URL:?Define AMID_API_URL, por ejemplo https://amid.mx}"
: "${AMID_API_TOKEN:?Define AMID_API_TOKEN}"

request_id() {
  uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid
}

api_get() {
  local path="$1"
  curl -fsS \
    -H "Authorization: Bearer ${AMID_API_TOKEN}" \
    -H "Accept: application/json" \
    -H "X-Request-ID: $(request_id)" \
    "${AMID_API_URL}${path}"
}

echo "== Doctors =="
api_get "/api/internal/v1/doctors?active=true&page=1&page_size=25" | jq .

echo "== Packages for doctor 7 =="
api_get "/api/internal/v1/packages?active=true&doctor_id=7&page=1&page_size=100" | jq .

echo "== Availability =="
api_get "/api/internal/v1/doctors/7/availability?package_id=50&date_from=2026-07-25&date_to=2026-07-31&timezone=America/Mexico_City" | jq .

echo "== Calendar =="
api_get "/api/internal/v1/doctors/7/calendar?date_from=2026-07-25&date_to=2026-07-31&timezone=America/Mexico_City" | jq .