<#
  공공곰 올인원 배포 빌드 — 기억하기: 프로젝트 루트에서

    .\gggom.ps1          → 웹(기본) = 번들 데이터 복사 + flutter build web
    .\gggom.ps1 web      → 동일
    .\gggom.ps1 win      → Windows
    .\gggom.ps1 apk      → Android APK
    .\gggom.ps1 bundle   → Android App Bundle
    .\gggom.ps1 ios      → iOS (맥·Xcode 필요)
    .\gggom.ps1 all      → web + windows 순서로 연속 빌드

  로컬 JSON 시드 소스: $env:BUNDLED_USER_DATA 없으면 assets\local_dev_state
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet("web", "win", "apk", "bundle", "ios", "all")]
  [string] $Target = "web"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$env:SUPABASE_URL = "https://nktapegejzujsxuhdcxz.supabase.co"
$env:SUPABASE_ANON_KEY = "sb_publishable_7KW5H2YdD-wVCX5x5wqqGQ_gVP9F4VK"

function Copy-GggomBundledWebData {
  $repoRoot = $PSScriptRoot
  $bundledSrc = if ($env:BUNDLED_USER_DATA -and (Test-Path $env:BUNDLED_USER_DATA)) {
    $env:BUNDLED_USER_DATA
  } else {
    Join-Path $repoRoot "assets\local_dev_state"
  }
  $bundledDest = Join-Path $repoRoot "web\bundled_data"
  New-Item -ItemType Directory -Force -Path $bundledDest | Out-Null
  $copied = New-Object System.Collections.Generic.List[string]
  $fixedNames = @(
    "local_peer_shop_listings_v1.json",
    "local_feed_v1.json"
  )
  foreach ($n in $fixedNames) {
    $src = Join-Path $bundledSrc $n
    if (Test-Path $src) {
      Copy-Item -LiteralPath $src -Destination (Join-Path $bundledDest $n) -Force
      $copied.Add($n) | Out-Null
    }
  }
  if (Test-Path $bundledSrc) {
    Get-ChildItem -LiteralPath $bundledSrc -Filter "local_chat_*_v1.json" -File -ErrorAction SilentlyContinue | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $bundledDest $_.Name) -Force
      if (-not $copied.Contains($_.Name)) { $copied.Add($_.Name) | Out-Null }
    }
  }
  $manifestPath = Join-Path $bundledDest "manifest.json"
  $manifestJson = ConvertTo-Json -InputObject @($copied.ToArray()) -Compress
  [System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-GggomWebBuild {
  Copy-GggomBundledWebData
  flutter build web --release `
    --pwa-strategy=none `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
}

switch ($Target) {
  "web" { Invoke-GggomWebBuild }
  "win" {
    flutter build windows --release `
      --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
      --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
  }
  "apk" {
    flutter build apk --release `
      --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
      --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
  }
  "bundle" {
    flutter build appbundle --release `
      --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
      --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
  }
  "ios" {
    flutter build ios --release `
      --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
      --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
  }
  "all" {
    Invoke-GggomWebBuild
    flutter build windows --release `
      --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
      --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
  }
}
