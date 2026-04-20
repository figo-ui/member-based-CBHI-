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
  RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
  
  echo "Fetching release info from $RELEASES_URL"
  JSON_DATA=$(curl -fsSL "$RELEASES_URL")
  
  ARCHIVE_PATH=$(echo "$JSON_DATA" | node -e '
    let raw = "";
    process.stdin.on("data", d => raw += d);
    process.stdin.on("end", () => {
      try {
        const data = JSON.parse(raw);
        const hash = data.current_release.stable;
        const release = data.releases.find(r => r.hash === hash);
        if (!release) {
          console.error("Stable release not found for hash:", hash);
          process.exit(1);
        }
        process.stdout.write(release.archive);
      } catch (e) {
        console.error("Failed to parse JSON:", e.message);
        process.exit(1);
      }
    });
  ')

  if [ -z "$ARCHIVE_PATH" ]; then
    echo "Error: Could not determine Flutter archive path."
    exit 1
  fi

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

