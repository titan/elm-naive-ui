// Shared upstream-key -> Elm field-name mapping for the theme tools.
//
// `gen-theme.mjs` writes field names; `verify/check-theme.mjs` maps them back to the
// upstream keys in `tools/generated/*.json` to compare values. Both must agree, so
// the rule lives here.
//
// Two upstream names are not valid Elm record fields:
//   - Elm keywords (`type`, `if`, ...)      -> suffix `_`
//   - leading-underscore names (`__invertScrollbar`, naive-ui's marker for an
//     internal, non-CSS-var theme value)    -> strip the prefix

const ELM_RESERVED = new Set([
  'type', 'if', 'then', 'else', 'case', 'of', 'let', 'in', 'as', 'port',
  'module', 'import', 'exposing', 'where', 'infix', 'alias'
])

// `__invertScrollbar` -> `invertScrollbar`; `type` -> `type_`.
export const toElmField = key => {
  const stripped = key.replace(/^_+/, '') || 'underscore'
  return ELM_RESERVED.has(stripped) ? `${stripped}_` : stripped
}

// `invertScrollbar` -> `__invertScrollbar`. `keys` are the upstream keys of the
// record being resolved. Throws when two upstream keys would collide, since that
// would make the mapping ambiguous.
export const fromElmField = (field, keys) => {
  const matches = keys.filter(k => toElmField(k) === field)
  if (matches.length > 1) {
    throw new Error(`ambiguous theme field '${field}': ${matches.join(', ')}`)
  }
  return matches[0]
}
