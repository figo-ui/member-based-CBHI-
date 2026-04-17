#!/usr/bin/env bash
set -euo pipefail

echo "Deploying member_based_cbhi to Vercel (production)..."
cd "$(dirname "$0")/.."

# Ensure vercel CLI is available
if ! command -v vercel &>/dev/null; then
  echo "vercel CLI not found. Install it with: npm i -g vercel"
  exit 1
fi

vercel --prod

echo ""
echo "Done! Check your Vercel dashboard for the live URL."
echo "Backend API: https://member-based-cbhi.vercel.app/api/v1"
