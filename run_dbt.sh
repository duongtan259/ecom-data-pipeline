#!/usr/bin/env bash
set -euo pipefail

LAYER="${LAYER:?LAYER env var required (bronze|silver|gold|reporting)}"
TARGET="${DBT_TARGET:-prod}"

case "$LAYER" in
  bronze)    SELECT=bronze    ;;
  silver)    SELECT=staging   ;;
  gold)      SELECT=marts     ;;
  reporting) SELECT=reporting ;;
  *) echo "Unknown LAYER: $LAYER" >&2; exit 1 ;;
esac

echo "=== dbt run: $LAYER (select=$SELECT, target=$TARGET) ==="
dbt run --profiles-dir /dbt --project-dir /dbt --select "$SELECT" --target "$TARGET"

if [[ "$LAYER" != "bronze" ]]; then
  echo "=== dbt test: $LAYER ==="
  dbt test --profiles-dir /dbt --project-dir /dbt --select "$SELECT" --target "$TARGET"
fi

echo "=== $LAYER complete ==="
