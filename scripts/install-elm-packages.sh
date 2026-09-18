#!/usr/bin/env bash
# Install Elm packages without going through github.com/zipball (which is blocked
# in this environment). Downloads the same source tarballs from codeload.github.com
# and unpacks them into $ELM_HOME/0.19.1/packages/<author>/<project>/<version>/.
#
# Usage:  scripts/install-elm-packages.sh [author/project@version ...]
#         scripts/install-elm-packages.sh            # installs the default set
#
# Respects ELM_HOME (default: $HOME/.elm-home).
set -euo pipefail

ELM_HOME="${ELM_HOME:-$HOME/.elm-home}"
VERSION_DIR="0.19.1"
root="$ELM_HOME/$VERSION_DIR/packages"

install_pkg() {
  local spec="$1"
  local author project version
  author="${spec%%/*}"
  project="${spec#*/}"; project="${project%%@*}"
  version="${spec##*@}"
  local dest="$root/$author/$project/$version"

  if [ -f "$dest/elm.json" ] && [ -d "$dest/src" ]; then
    echo "  = $author/$project $version (cached)"
    return 0
  fi
  rm -rf "$dest"
  mkdir -p "$dest"
  local url="https://codeload.github.com/$author/$project/tar.gz/refs/tags/$version"
  if ! curl -fsSL --max-time 180 "$url" -o /tmp/elm-pkg-$$.tgz; then
    echo "  ! failed to download $author/$project $version from $url" >&2
    rm -rf "$dest"
    return 1
  fi
  tar -xzf /tmp/elm-pkg-$$.tgz -C "$dest" --strip-components=1
  rm -f /tmp/elm-pkg-$$.tgz
  echo "  + $author/$project $version"
}

DEFAULT_PKGS=(
  elm/core@1.0.5
  elm/json@1.1.3
  elm/html@1.0.0
  elm/virtual-dom@1.0.3
  elm/time@1.0.0
  elm/url@1.0.0
  elm/browser@1.0.2
  mdgriffith/elm-ui@1.1.8
)

pkgs=("$@")
if [ ${#pkgs[@]} -eq 0 ]; then
  pkgs=("${DEFAULT_PKGS[@]}")
fi

echo "ELM_HOME=$ELM_HOME"
for p in "${pkgs[@]}"; do
  install_pkg "$p"
done
echo "done."
