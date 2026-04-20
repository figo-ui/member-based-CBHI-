#!/usr/bin/env bash
set -euo pipefail

# ── Fix 1: Allow Flutter to run as root (Vercel runs as root) ────────────────
export FLUTTER_ALLOW_ROOT=1 PUB_ALLOW_SUDO=1

# ── Fix 2: Fix git "dubious ownership" errors ────────────────────────────────
git config --global --add safe.directory '*' || true

# Use a relative directory within the project or $HOME
FLUTTER_ROOT="$HOME/.flutter-sdk"

echo "Using FLUTTER_ROOT: $FLUTTER_ROOT"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  echo "Installing Flutter SDK..."

  # Fetch latest stable release archive path via stdin
  # Pin Flutter version to avoid unexpected breakage from "latest stable"
  FLUTTER_VERSION="3.41.7"
  ARCHIVE_PATH="stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

  echo "Downloading Flutter from: https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE_PATH}"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE_PATH}" -o /tmp/flutter.tar.xz
  
  rm -rf "$FLUTTER_ROOT"
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  
  echo "Extracting Flutter..."
  tar -xf /tmp/flutter.tar.xz -C "$(dirname "$FLUTTER_ROOT")"
  mv "$(dirname "$FLUTTER_ROOT")/flutter" "$FLUTTER_ROOT"
  rm /tmp/flutter.tar.xz
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

# Enable web explicitly
echo "Configuring Flutter..."
flutter config --enable-web --no-analytics
flutter --version

echo "Running pub get..."
flutter pub get

API_URL="${CBHI_API_BASE_URL:-https://member-based-cbhi.vercel.app/api/v1}"
echo "Building with API: $API_URL"

echo "Starting web build..."
flutter build web --release --verbose --no-source-maps \
  --web-renderer auto \
  --dart-define=CBHI_API_BASE_URL="$API_URL" \
  --dart-define=APP_ENV="production"

