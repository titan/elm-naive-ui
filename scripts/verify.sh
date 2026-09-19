#!/usr/bin/env bash
# One-command verification for elm-naive-ui.
#
#   scripts/verify.sh
#
# Checks, in order:
#   1. every emitted n-* class exists in the extracted stylesheet   (static)
#   2. the library compiles                                          (elm make)
#   3. the example page compiles                                     (elm make)
#   4. every component root renders with the elm-ui bridge working   (jsdom)
#   5. the foundation test suite passes                              (tests/run.sh)
#   6. sources are elm-format clean
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"

if [ ! -d "$ELM_HOME/0.19.1/packages/mdgriffith/elm-ui" ]; then
  echo "== installing elm packages into $ELM_HOME =="
  ./scripts/install-elm-packages.sh
fi

echo "== 1/6 class coverage =="
node tools/verify/check-classes.mjs

echo "== 2/6 library build =="
elm make

echo "== 3/6 example build =="
( cd examples && elm make src/Main.elm --output=index.html )

echo "== 4/6 component DOM/bridge =="
node tools/verify/check-dom.mjs examples/index.html

echo "== 5/6 foundation tests =="
bash tests/run.sh

echo "== 6/6 elm-format =="
elm-format --validate src examples tests

echo
echo "ALL CHECKS PASSED"
