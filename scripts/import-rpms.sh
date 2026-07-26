#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${1:-public}"
RPM_DIR="${2:-tmp-rpms}"

error() { printf '\033[0;31mx %s\033[0m\n' "$1" >&2; }
info() { printf '\033[0;36m-> %s\033[0m\n' "$1"; }

command -v rpm >/dev/null || { error "rpm not found"; exit 1; }

if ! find "$RPM_DIR" -type f -name '*.rpm' | grep -q .; then
  error "No RPM files found in $RPM_DIR"
  exit 1
fi

while IFS= read -r -d '' rpm_file; do
  filename="$(basename "$rpm_file")"
  arch="$(rpm -qp --queryformat '%{ARCH}' "$rpm_file")"

  target_dir="$PUBLIC_DIR/rpm/$arch"
  mkdir -p "$target_dir"
  info "Importing $filename into $target_dir"
  cp "$rpm_file" "$target_dir/"
done < <(find "$RPM_DIR" -type f -name '*.rpm' -print0)
