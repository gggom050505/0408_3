#!/usr/bin/env bash
# Vercel buildCommand는 256자 제한 → 전체 빌드는 여기서 실행합니다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -d .flutter/bin ]]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter
fi
export PATH="$PATH:$ROOT/.flutter/bin"

flutter config --no-analytics
flutter pub get

# Vercel env vars -> Flutter compile-time defines.
# Empty values are allowed; app-side flags decide enabled features.
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

mkdir -p build/web/oracle_cards
if [[ -d assets/oracle ]]; then
  find assets/oracle -maxdepth 1 -type f -name 'oracle*.png' -exec cp -f {} build/web/oracle_cards/ \;
fi
