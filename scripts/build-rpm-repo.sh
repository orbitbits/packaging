#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-public}"

info() { printf '\033[0;36m-> %s\033[0m\n' "$1"; }
warn() { printf '\033[0;33m! %s\033[0m\n' "$1"; }
error() { printf '\033[0;31mx %s\033[0m\n' "$1" >&2; }

command -v createrepo_c >/dev/null || { error "createrepo_c not found"; exit 1; }

if ! find "$OUTPUT_DIR" -type f -name '*.rpm' | grep -q .; then
  warn "No RPM packages found under $OUTPUT_DIR"
  exit 0
fi

sign_repomd() {
  local repomd="$1"

  if [ "${SIGN_REPO:-false}" != "true" ]; then
    return 0
  fi

  command -v gpg >/dev/null || { error "gpg not found"; exit 1; }
  : "${GPG_FINGERPRINT:?GPG_FINGERPRINT is required when SIGN_REPO=true}"
  : "${GPG_PASSPHRASE_FILE:?GPG_PASSPHRASE_FILE is required when SIGN_REPO=true}"

  gpg --batch --pinentry-mode loopback \
    --passphrase-file "$GPG_PASSPHRASE_FILE" \
    --local-user "$GPG_FINGERPRINT" \
    --yes --detach-sign --armor "$repomd"
}

if [ "${SIGN_RPMS:-false}" = "true" ]; then
  command -v rpm >/dev/null || { error "rpm not found"; exit 1; }
  command -v gpg >/dev/null || { error "gpg not found"; exit 1; }
  : "${GPG_FINGERPRINT:?GPG_FINGERPRINT is required when SIGN_RPMS=true}"
  : "${GPG_PASSPHRASE_FILE:?GPG_PASSPHRASE_FILE is required when SIGN_RPMS=true}"

  cat > "$HOME/.rpmmacros" <<EOF
%_signature gpg
%_gpg_name $GPG_FINGERPRINT
%_gpg_path $HOME/.gnupg
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --no-armor --no-tty --pinentry-mode loopback --passphrase-file $GPG_PASSPHRASE_FILE --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}
EOF

  while IFS= read -r -d '' rpm_file; do
    info "Signing RPM $(basename "$rpm_file")"
    rpm --addsign "$rpm_file"
  done < <(find "$OUTPUT_DIR" -type f -name '*.rpm' -print0)
fi

info "Generating aggregate RPM metadata for $OUTPUT_DIR"
createrepo_c --no-database "$OUTPUT_DIR"
sign_repomd "$OUTPUT_DIR/repodata/repomd.xml"

while IFS= read -r -d '' dir; do
  [ "$dir" = "$OUTPUT_DIR" ] && continue

  info "Generating RPM metadata for $dir"
  createrepo_c --no-database "$dir"
  sign_repomd "$dir/repodata/repomd.xml"
done < <(find "$OUTPUT_DIR" -type f -name '*.rpm' -printf '%h\0' | sort -zu)
