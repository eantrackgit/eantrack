#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?Defina SUPABASE_URL antes do build.}"
: "${SUPABASE_ANON_KEY:?Defina SUPABASE_ANON_KEY antes do build.}"

fvm flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

cp deploy/operational.htaccess build/web/.htaccess

echo "Build web de producao pronta em build/web"
