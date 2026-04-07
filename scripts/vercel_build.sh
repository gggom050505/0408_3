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
flutter build web --release

mkdir -p build/web/oracle_cards
if [[ -d assets/oracle ]]; then
  find assets/oracle -maxdepth 1 -type f -name 'oracle*.png' -exec cp -f {} build/web/oracle_cards/ \;
fi
