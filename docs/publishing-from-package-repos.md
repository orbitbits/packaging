# Publishing from package repositories

Product packaging repositories should build artifacts, then publish them to this
repository. They should not publish APT or RPM metadata directly.

## Recommended flow

1. Build the package in the product repository.
2. Upload the package as a short-lived GitHub Actions artifact.
3. Trigger `orbitbits/packaging` with the workflow `run_id` and artifact name.
4. Let `orbitbits/packaging` import the artifact into `gh-pages`, regenerate
   metadata, sign it, and deploy GitHub Pages.

## DEB example

```yaml
- name: Trigger packaging publish
  env:
    GH_TOKEN: ${{ secrets.ORBITBITS_PACKAGING_TOKEN }}
  run: |
    gh api repos/orbitbits/packaging/dispatches \
      -f event_type=publish-package \
      -f client_payload[package_type]=deb \
      -f client_payload[source_repository]=orbitbits/tildr-deb \
      -f client_payload[run_id]="${{ github.run_id }}" \
      -f client_payload[artifact_pattern]="tildr-deb-*"
```

## RPM example

```yaml
- name: Trigger packaging publish
  env:
    GH_TOKEN: ${{ secrets.ORBITBITS_PACKAGING_TOKEN }}
  run: |
    gh api repos/orbitbits/packaging/dispatches \
      -f event_type=publish-package \
      -f client_payload[package_type]=rpm \
      -f client_payload[source_repository]=orbitbits/tildr-rpm \
      -f client_payload[run_id]="${{ github.run_id }}" \
      -f client_payload[artifact_pattern]="tildr-rpm"
```

## Required token

Create `ORBITBITS_PACKAGING_TOKEN` with permission to trigger workflows in
`orbitbits/packaging`. The same token should be available to `orbitbits/packaging`
with permission to read Actions artifacts from the package repositories.

## Domain note

This repository publishes one static GitHub Pages tree at
`https://packages.orbitbits.com`:

- `https://packages.orbitbits.com/deb/` contains `dists/` and `pool/` for APT
- `https://packages.orbitbits.com/rpm/` contains aggregate RPM metadata in
  `repodata/` plus architecture-specific repositories such as `x86_64/`
- `https://packages.orbitbits.com/keys/` contains the single OrbitBits package
  signing public key
- `orbitbits.list` and `orbitbits.repo` client configuration files

GitHub Pages stores a single `CNAME` file per repository, so this repository is
configured for `packages.orbitbits.com`.
