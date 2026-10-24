#!/usr/bin/env bash
# Generate the package API documentation (docs.json) for publishing.
#
#   scripts/gen-docs.sh
#
# Runs `elm make --docs=docs.json`, which enforces the full Elm docs
# contract: every exposed module must have a module comment containing an
# @docs section that mentions exactly its exposed names, and every exposed
# top-level declaration needs its own doc comment. A failure here means the
# published API reference would be broken — fix the reported module.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"

if [ ! -d "$ELM_HOME/0.19.1/packages/mdgriffith/elm-ui" ]; then
  ./scripts/install-elm-packages.sh
fi

# Same stale-interface guard as verify.sh: a docs build trusts elm-stuff
# interfaces, so bust them when any build input is newer.
if [ -d elm-stuff ] \
  && find elm.json src -newer elm-stuff -print -quit 2>/dev/null | grep -q .; then
  rm -rf elm-stuff
fi

elm make --docs=docs.json --output=/dev/null

node - "$here/docs.json" <<'EOF'
// Post-conditions the compiler does not check: docs.json exists, is
// non-empty, and every documented module carries a real comment (the
// published reference renders module docs verbatim).
const fs = require("fs");
const docs = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (!Array.isArray(docs) || docs.length === 0) {
  console.error("docs.json is empty — nothing to publish");
  process.exit(1);
}
const bare = docs.filter((m) => !m.comment || !m.comment.trim());
if (bare.length > 0) {
  console.error("modules without doc comments: " + bare.map((m) => m.name).join(", "));
  process.exit(1);
}
let entries = 0;
for (const m of docs) entries += (m.entries || []).length;
console.log(`docs.json: ${docs.length} modules, ${entries} documented entries`);
EOF
