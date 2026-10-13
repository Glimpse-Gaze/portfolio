#!/usr/bin/env bash
set -euo pipefail

# Blowfish requires Hugo extended. Pin the same release GitHub Pages uses.
HUGO_VERSION=0.165.0
TZ=Europe/London
HUGO_CACHEDIR="${PWD}/.vercel/cache/hugo"

cleanup() {
  if [[ -n "${build_temp_dir:-}" && -d "${build_temp_dir}" ]]; then
    rm -rf "${build_temp_dir}"
  fi
}
trap cleanup EXIT SIGINT SIGTERM

main() {
  export TZ
  export HUGO_CACHEDIR

  build_temp_dir=$(mktemp -d)
  mkdir -p "${HOME}/.local/hugo"

  echo "Installing Hugo extended ${HUGO_VERSION}..."
  curl -sfL --output-dir "${build_temp_dir}" -O "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
  tar -C "${HOME}/.local/hugo" -xf "${build_temp_dir}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
  export PATH="${HOME}/.local/hugo:${PATH}"

  hugo version

  if [[ -d .git ]]; then
    git config --global core.quotepath false
    if [[ $(git rev-parse --is-shallow-repository) == true ]]; then
      echo "Fetching full Git history..."
      git fetch --unshallow
    fi
    if [[ -f .gitmodules ]]; then
      echo "Initializing Git submodules..."
      git submodule update --init --recursive
    fi
  elif [[ ! -d themes/blowfish/layouts ]]; then
    echo "Theme submodule themes/blowfish is missing and this build has no Git metadata." >&2
    exit 1
  fi

  hugo build --gc --minify
}

main "$@"
