#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${1:-public}"
DEB_DIR="${2:-tmp-debs}"

error() { printf '\033[0;31mx %s\033[0m\n' "$1" >&2; }
info() { printf '\033[0;36m-> %s\033[0m\n' "$1"; }

command -v dpkg-deb >/dev/null || { error "dpkg-deb not found"; exit 1; }

if ! find "$DEB_DIR" -type f -name '*.deb' | grep -q .; then
  error "No DEB files found in $DEB_DIR"
  exit 1
fi

while IFS= read -r -d '' deb_file; do
  package="$(dpkg-deb --field "$deb_file" Package)"
  first_letter="$(printf '%s' "$package" | cut -c1)"
  target_dir="$PUBLIC_DIR/deb/pool/main/$first_letter/$package"

  mkdir -p "$target_dir"
  info "Importing $(basename "$deb_file") into $target_dir"
  cp "$deb_file" "$target_dir/"
done < <(find "$DEB_DIR" -type f -name '*.deb' -print0)
