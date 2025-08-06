#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/comfyui
# The network volume is always at /runpod-volume on serverless workers
VOL_ROOT=/runpod-volume

echo "[startup] Linking network volume directories..."
mkdir -p "$APP_DIR" || true

# Link all necessary directories from the root of the network volume
ln -sfn "$VOL_ROOT/models"        "$APP_DIR/models"
ln -sfn "$VOL_ROOT/custom_nodes"  "$APP_DIR/custom_nodes"
ln -sfn "$VOL_ROOT/input"         "$APP_DIR/input"
ln -sfn "$VOL_ROOT/output"        "$APP_DIR/output"
ln -sfn "$VOL_ROOT/workflows"     "$APP_DIR/workflows"

echo "[startup] Symlinks created. Handing off to base image entrypoint."
exec /start.sh
