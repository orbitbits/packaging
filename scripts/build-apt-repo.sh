#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-public}"
CODENAMES="${APT_CODENAMES:-stable}"
ARCHITECTURES="${APT_ARCHITECTURES:-amd64}"
ORIGIN="${APT_ORIGIN:-OrbitBits}"
LABEL="${APT_LABEL:-OrbitBits Package Repository}"
DESCRIPTION="${APT_DESCRIPTION:-APT repository for OrbitBits packages}"

info() { printf '\033[0;36m-> %s\033[0m\n' "$1"; }
warn() { printf '\033[0;33m! %s\033[0m\n' "$1"; }
error() { printf '\033[0;31mx %s\033[0m\n' "$1" >&2; }

command -v dpkg-scanpackages >/dev/null || { error "dpkg-scanpackages not found"; exit 1; }
command -v apt-ftparchive >/dev/null || { error "apt-ftparchive not found"; exit 1; }

mkdir -p "$OUTPUT_DIR/pool/main"

if ! find "$OUTPUT_DIR/pool" -type f -name '*.deb' | grep -q .; then
  warn "No DEB packages found under $OUTPUT_DIR/pool"
fi

for codename in $CODENAMES; do
  for arch in $ARCHITECTURES; do
    mkdir -p "$OUTPUT_DIR/dists/$codename/main/binary-$arch"
  done
done

(
  cd "$OUTPUT_DIR"

  for codename in $CODENAMES; do
    for arch in $ARCHITECTURES; do
      dir="dists/$codename/main/binary-$arch"
      info "Generating APT Packages for $codename/$arch"
      dpkg-scanpackages --arch "$arch" --multiversion pool/ /dev/null > "$dir/Packages"
      gzip -9 -k -f "$dir/Packages"
    done

    info "Generating APT Release for $codename"
    apt-ftparchive \
      -o APT::FTPArchive::Release::Origin="$ORIGIN" \
      -o APT::FTPArchive::Release::Label="$LABEL" \
      -o APT::FTPArchive::Release::Suite="$codename" \
      -o APT::FTPArchive::Release::Codename="$codename" \
      -o APT::FTPArchive::Release::Architectures="$ARCHITECTURES" \
      -o APT::FTPArchive::Release::Components="main" \
      -o APT::FTPArchive::Release::Description="$DESCRIPTION" \
      release "dists/$codename" > "dists/$codename/Release"

    if [ "${SIGN_REPO:-false}" = "true" ]; then
      command -v gpg >/dev/null || { error "gpg not found"; exit 1; }
      : "${GPG_FINGERPRINT:?GPG_FINGERPRINT is required when SIGN_REPO=true}"
      : "${GPG_PASSPHRASE_FILE:?GPG_PASSPHRASE_FILE is required when SIGN_REPO=true}"

      info "Signing APT Release for $codename"
      gpg --batch --pinentry-mode loopback \
        --passphrase-file "$GPG_PASSPHRASE_FILE" \
        --local-user "$GPG_FINGERPRINT" \
        --yes --clearsign -o "dists/$codename/InRelease" "dists/$codename/Release"

      gpg --batch --pinentry-mode loopback \
        --passphrase-file "$GPG_PASSPHRASE_FILE" \
        --local-user "$GPG_FINGERPRINT" \
        --yes -abs -o "dists/$codename/Release.gpg" "dists/$codename/Release"
    fi
  done
)
