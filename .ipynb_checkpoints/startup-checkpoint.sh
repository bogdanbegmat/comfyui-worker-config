#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/comfyui
VOL_ROOT=/runpod-volume

echo "[startup] Linking network volume directories..."
mkdir -p "$APP_DIR" || true

# Link only the directories that contain data, not code.
ln -sfn "$VOL_ROOT/models"    "$APP_DIR/models"
ln -sfn "$VOL_ROOT/input"     "$APP_DIR/input"
ln -sfn "$VOL_ROOT/output"    "$APP_DIR/output"
ln -sfn "$VOL_ROOT/workflows" "$APP_DIR/workflows"

echo "[startup] Symlinks created. Custom nodes are baked into the image."
echo "[startup] Handing off to base image entrypoint."
exec /start.sh