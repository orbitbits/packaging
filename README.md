# OrbitBits Packaging

Central package repositories for OrbitBits Linux packages.

This repository is the GitHub Pages publishing target for all OrbitBits `.deb`
and `.rpm` artifacts. Product repositories, such as `orbitbits/tildr-deb` and
`orbitbits/tildr-rpm`, should keep building package files, then ask this
repository to import the release artifacts into `gh-pages`.

## Branch layout

```text
main
  _data/
  _layouts/
  _sass/
  assets/
  tools/rb/
  .github/workflows/
  README.md

gh-pages
  index.html
  keys/
    orbitbits.gpg
  deb/
    index.html
    dists/
    pool/
  rpm/
    index.html
    repodata/
    x86_64/
```

The generated repository is assembled in `public/` during CI and deployed to
`gh-pages`:

```text
public/
  index.html
  deb/
    index.html
    dists/
    pool/
  rpm/
    index.html
    repodata/
    x86_64/
```

Do not edit `public/` by hand.

## Client URLs

Repository metadata URLs:

- `https://packages.orbitbits.com/deb/dists/stable/main/binary-amd64/Packages.gz`
- `https://packages.orbitbits.com/deb/dists/stable/Release`
- `https://packages.orbitbits.com/rpm/repodata/repomd.xml`

APT:

```sh
curl -fsSL https://packages.orbitbits.com/keys/orbitbits.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/orbitbits.gpg

echo "deb [signed-by=/usr/share/keyrings/orbitbits.gpg] https://packages.orbitbits.com/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/orbitbits.list

sudo apt update
```

RPM:

```sh
sudo rpm --import https://packages.orbitbits.com/keys/orbitbits.gpg
sudo dnf config-manager addrepo --from-repofile=https://packages.orbitbits.com/rpm/orbitbits.repo
sudo dnf install <package>
```

## Local usage

Install the repository tools:

```sh
sudo apt-get update
sudo apt-get install -y dpkg-dev apt-utils createrepo-c rpm gnupg
bundle install
```

Build the local repository:

```sh
make build
```

Serve it locally:

```sh
make serve
```

## Publishing model

Package-specific repositories should not deploy package indexes themselves.
They should build package artifacts and trigger this repository to import them:

- DEB artifacts are imported into `gh-pages` under `deb/pool/main/...`.
- RPM artifacts are imported into `gh-pages` under `rpm/<arch>/...`.

When this repository receives a dispatch or manual publish request, GitHub
Actions checks out the current `gh-pages`, imports the new package files,
rebuilds APT and RPM metadata, signs repository metadata with the OrbitBits GPG
key, generates temporary Jekyll pages for package directories, builds the Jekyll
site, and deploys the updated `public/` tree back to GitHub Pages.

Jekyll owns the main site pages, shared CSS, SEO tags, footer, and directory
layouts. Ruby scripts in `tools/rb/` assemble repository payload and generate
temporary `_pages/` entries for dynamic package directories such as `deb/`,
`rpm/`, `keys/`, and nested metadata directories.

Required GitHub Actions secrets:

- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`

See [docs/publishing-from-package-repos.md](docs/publishing-from-package-repos.md)
for workflow snippets that can be added to `tildr-deb`, `tildr-rpm`, and future
package repositories.
