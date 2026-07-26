#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-public}"

mkdir -p "$OUTPUT_DIR/deb" "$OUTPUT_DIR/rpm"

bash scripts/build-apt-repo.sh "$OUTPUT_DIR/deb"
bash scripts/build-rpm-repo.sh "$OUTPUT_DIR/rpm"
bash scripts/write-client-configs.sh "$OUTPUT_DIR"
