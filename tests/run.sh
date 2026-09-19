#!/usr/bin/env bash
# Build and run the elm-naive-ui foundation test suite.
#
#   tests/run.sh
#
# Exits non-zero if any assertion fails.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"

# jsdom is test-only and required to read the rendered results without a browser.
if [ ! -d "$here/node_modules/jsdom" ]; then
  echo "== installing jsdom (test-only dependency) =="
  ( cd "$here" && npm --cache "${NPM_CACHE:-/tmp/npm-cache}" install --no-audit --no-fund --loglevel=error )
fi

cd "$here"

echo "== building tests (ELM_HOME=$ELM_HOME) =="
elm make src/Main.elm --output=index.html

echo "== running assertions =="
node inspect.mjs index.html
