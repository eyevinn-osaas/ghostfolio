#!/usr/bin/env bash
# OSC entrypoint for Ghostfolio: maps OSC conventions to Ghostfolio's own
# variables, then hands over to upstream's entrypoint (prisma migrate deploy,
# db seed, node main). Ghostfolio reads PORT and HOST itself.
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL (PostgreSQL URL, postgresql://user:password@host:5432/db) is required}"
: "${REDIS_HOST:?REDIS_HOST (Redis/Valkey host) is required}"
: "${ACCESS_TOKEN_SALT:?ACCESS_TOKEN_SALT is required and must stay the same across restarts}"
: "${JWT_SECRET_KEY:?JWT_SECRET_KEY is required and must stay the same across restarts}"

export PORT="${PORT:-8080}"
export REDIS_PORT="${REDIS_PORT:-6379}"

# Public URL (used for absolute links), no path.
if [[ -n "${OSC_HOSTNAME:-}" && -z "${ROOT_URL:-}" ]]; then
  export ROOT_URL="https://${OSC_HOSTNAME}"
fi

# Prisma's default connect timeout is 5 s, too short while a database is still
# starting. Add a longer one unless the URL already sets it; keep other params.
if [[ "${DATABASE_URL}" != *connect_timeout=* ]]; then
  if [[ "${DATABASE_URL}" == *\?* ]]; then
    export DATABASE_URL="${DATABASE_URL}&connect_timeout=300"
  else
    export DATABASE_URL="${DATABASE_URL}?connect_timeout=300"
  fi
fi

exec /ghostfolio/entrypoint.sh "$@"
