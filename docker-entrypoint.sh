#!/usr/bin/env bash
set -e

# Rails migration entrypoint
# Runs pending migrations unless SKIP_DB_MIGRATE=1

if [ "${SKIP_DB_MIGRATE}" = "1" ]; then
  echo "Skipping migrations (SKIP_DB_MIGRATE=1)"
else
  echo "Running database migrations..."
  bundle exec rails db:migrate || {
    echo "Migrations failed" >&2
    exit 1
  }
fi

exec "$@"
