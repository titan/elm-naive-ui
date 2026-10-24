#!/usr/bin/env bash
# One-command verification for elm-naive-ui.
#
#   scripts/verify.sh
#
# Checks, in order:
#   1. every emitted n-* class exists in the extracted stylesheet   (static)
#   2. every emitted theme value equals the executed upstream value  (static)
#   3. elm.json exposes every module in src/                         (static)
#   4. the library compiles                                          (elm make)
#   5. the example page compiles                                     (elm make)
#   6. every component root renders with the elm-ui bridge working   (jsdom)
#   7. the foundation test suite passes                              (tests/run.sh)
#   8. sources are elm-format clean
#   9. the API documentation builds (elm make --docs)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"

# Stale-interface guard: a changed src/ or elm.json can leave elm-stuff interface
# files that hide TYPE errors (bit us once: a stub commit broke Popselect's record
# literal and `elm make --docs` still passed). elm-stuff is only trustworthy when
# no build input is newer than it — bust it exactly then (warm runs cost one find).
bust_stale_elm_stuff() {
  local dir="$1"
  if [ -d "$dir/elm-stuff" ] \
    && find "$dir/elm.json" "$dir/src" -newer "$dir/elm-stuff" -print -quit 2>/dev/null | grep -q .; then
    echo "  (busting stale elm-stuff in $dir)"
    rm -rf "$dir/elm-stuff"
  fi
}

if [ ! -d "$ELM_HOME/0.19.1/packages/mdgriffith/elm-ui" ]; then
  echo "== installing elm packages into $ELM_HOME =="
  ./scripts/install-elm-packages.sh
fi

echo "== 1/9 class coverage =="
node tools/verify/check-classes.mjs

echo "== 2/9 theme values =="
node tools/verify/check-theme.mjs

echo "== 3/9 module exposure =="
node tools/verify/check-exposure.mjs

echo "== 4/9 library build =="
bust_stale_elm_stuff "$here"
elm make --output=/dev/null

echo "== 5/9 example build =="
bust_stale_elm_stuff "$here/examples"
node tools/gen-demo-code.mjs --check
( cd examples && elm make src/Main.elm --output=index.html )

echo "== 6/9 component DOM/bridge =="
node tools/verify/check-dom.mjs examples/index.html

echo "== 7/9 foundation tests =="
bust_stale_elm_stuff "$here/tests"
bash tests/run.sh

echo "== 8/9 elm-format =="
elm-format --validate src examples tests

echo "== 9/9 API docs =="
# The published API reference must always build: every exposed module
# documented (@docs complete) — see scripts/gen-docs.sh.
bash scripts/gen-docs.sh

echo
echo "ALL CHECKS PASSED"
