#!/usr/bin/env bash
# One-command verification for elm-naive-ui.
#
#   scripts/verify.sh
#
# Checks, in order:
#   1. every emitted n-* class exists in the extracted stylesheet   (static)
#   2. every emitted theme value equals the executed upstream value  (static)
#   3. the library compiles                                          (elm make)
#   4. the example page compiles                                     (elm make)
#   5. every component root renders with the elm-ui bridge working   (jsdom)
#   6. the foundation test suite passes                              (tests/run.sh)
#   7. sources are elm-format clean
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"

if [ ! -d "$ELM_HOME/0.19.1/packages/mdgriffith/elm-ui" ]; then
  echo "== installing elm packages into $ELM_HOME =="
  ./scripts/install-elm-packages.sh
fi

echo "== 1/7 class coverage =="
node tools/verify/check-classes.mjs

echo "== 2/7 theme values =="
node tools/verify/check-theme.mjs

echo "== 3/7 library build =="
elm make

echo "== 4/7 example build =="
( cd examples && elm make src/Main.elm --output=index.html )

echo "== 5/7 component DOM/bridge =="
node tools/verify/check-dom.mjs examples/index.html

echo "== 6/7 foundation tests =="
bash tests/run.sh

echo "== 7/7 elm-format =="
elm-format --validate src examples tests

echo
echo "ALL CHECKS PASSED"
