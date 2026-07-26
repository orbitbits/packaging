#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-public}"
APT_URL="${APT_URL:-https://packages.orbitbits.com/deb}"
RPM_URL="${RPM_URL:-https://packages.orbitbits.com/rpm}"
KEY_URL="${KEY_URL:-https://packages.orbitbits.com/keys/orbitbits.gpg}"

mkdir -p "$OUTPUT_DIR/deb" "$OUTPUT_DIR/rpm"

cat > "$OUTPUT_DIR/deb/orbitbits.list" <<EOF
deb [signed-by=/usr/share/keyrings/orbitbits.gpg] $APT_URL stable main
EOF

cat > "$OUTPUT_DIR/rpm/orbitbits.repo" <<EOF
[orbitbits]
name=OrbitBits Package Repository
baseurl=$RPM_URL/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$KEY_URL
EOF
