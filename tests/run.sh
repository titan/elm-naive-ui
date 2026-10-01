#!/usr/bin/env bash
# Build and run the elm-naive-ui foundation test suite.
#
#   tests/run.sh
#
# Also builds the live showcase page (examples/index.html) that inspect.mjs's
# Live · Overlays interaction phase drives in a second jsdom instance.
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

echo "== building live showcase page (examples) =="
( cd "$here/../examples" && elm make src/Main.elm --output=index.html )

echo "== running assertions =="
node inspect.mjs index.html
