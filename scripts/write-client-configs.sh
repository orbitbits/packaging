#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-public}"
APT_URL="${APT_URL:-https://packages.orbitbits.com/deb}"
RPM_URL="${RPM_URL:-https://packages.orbitbits.com/rpm}"

mkdir -p "$OUTPUT_DIR/deb" "$OUTPUT_DIR/rpm"

cat > "$OUTPUT_DIR/orbitbits.list" <<EOF
deb [signed-by=/usr/share/keyrings/orbitbits.gpg] $APT_URL stable main
EOF

cp "$OUTPUT_DIR/orbitbits.list" "$OUTPUT_DIR/tildr.list"
cp "$OUTPUT_DIR/orbitbits.list" "$OUTPUT_DIR/deb/orbitbits.list"
cp "$OUTPUT_DIR/orbitbits.list" "$OUTPUT_DIR/deb/tildr.list"

cat > "$OUTPUT_DIR/orbitbits.repo" <<EOF
[orbitbits]
name=OrbitBits Package Repository
baseurl=$RPM_URL/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$RPM_URL/orbitbits-packaging-pub.gpg
EOF

cp "$OUTPUT_DIR/orbitbits.repo" "$OUTPUT_DIR/tildr.repo"
cp "$OUTPUT_DIR/orbitbits.repo" "$OUTPUT_DIR/rpm/orbitbits.repo"
cp "$OUTPUT_DIR/orbitbits.repo" "$OUTPUT_DIR/rpm/tildr.repo"
