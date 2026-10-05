# b6 pin derivations — from upstream bytes ONLY (pre-feat, pins-first)

Derived from DataTable.spec.tsx + Body.tsx/Header.tsx/use-group-header.ts math.
RED-history discipline: these beat port output; a RED that survives re-derivation
from these bytes is a port bug.

## Eq pins (tests/src/Main.elm, append after b5 filter block)

Fixture A (spec :1360): columns [name(w100), age(w100, children=[test1, test2])]

- `leafColumns` → keys [name, test1, test2] (age absent).
- `headerRows` →
  - row 0: name{colIndex 0, colSpan 1, rowSpan 2, isLast False},
    age{colIndex 1, colSpan 2, rowSpan 1, isLast True}
  - row 1: test1{colIndex 1, colSpan 1, rowSpan 1, isLast False},
    test2{colIndex 2, colSpan 1, rowSpan 1, isLast True}
  (totalRowSpan 3, maxDepth 1; leaf rowSpan = maxDepth−depth+1.)

Fixture B (titleColSpan): columns [a(titleColSpan 2), b, c] →
row 0: a{0, 2, 1, isLast True (0+2===3)}, c{2, 1, 1, isLast True}; b SWALLOWED
(no rowItem; hideUntilIndex covers leaf index 1).

Fixture C (children Just []): [x(children=[])] → row 0:
x{0, 0, 1, isLast TRUE (0+0===0)}; leafColumns → [].

Fixture D (group + fixed): [g(children=[a(fixed left, w100), b(w100)]), c(w50)] →
fixedColumnLeftMap over LEAVES only (b4 formula): a start 0, c start 100; g absent.

TRAP: the 7 exhaustive dt Column literals gain
`children = Nothing, titleColSpan = Nothing, colSpan = Nothing, rowSpan = Nothing`.

## DOM pins (tests/inspect.mjs, dt block tail before `// --- report`;
fixtures before dtSelCol)

P1 summary (spec :847): 2 cols name/age; 10 rows {name i, age i}; summary →
[name: {value 45, colSpan 1, rowSpan 2}, age: {value 45, colSpan 2, rowSpan 1}]:
- `.n-data-table-td--summary` count 2 (order name, age).
- [0] data-col-key 'name', colspan '1', rowspan '2', textContent '45'.
- [1] data-col-key 'age', colspan '2', rowspan '1', textContent '45'
  (jsdom cell text via regex/includes, not exact equality).
- `tr.n-data-table-tr--summary` count 1; NO tfoot element.
- Placement bottom ⇒ summary tr is the LAST tr (after 10 data trs).
- --last-row math (rowCount 11, colCount 2): age td displayedRowIndex 10 + 1
  === 11 ⇒ HAS `n-data-table-td--last-row`; name td 10+2=12 ⇒ NOT.
- --last-col: name 0+1===2 no; age 1+2===2 no ⇒ neither.
- striped=True variant: summary tr has NO `--striped` class.

P2 summaryPlacement top: same fixture, placement top ⇒ summary tr is FIRST tr.

P3 merge (spec :1113): 2 cols; name rowSpan (i==0?2:1), colSpan (i==0?3:1);
5 rows; rowKey name:
- First tbody td: colspan '3', rowspan '2'.
- tbody tr count 5; SECOND tr has exactly 1 td, data-col-key 'age'
  (name cell swallowed by cordToPass row 1 col 0).
- --last-col: every age td (1+1===2) HAS it; row-0 name (0+3===2) NOT.
- --last-row: last tr's age td (4+1===5) HAS it.

P4 group (spec :1360): thead:
- tr count 2; th count 2 + 2.
- th[name] colspan '1' rowspan '2'; th[age] colspan '2' rowspan '1';
  th[test1] colspan '1' rowspan '1'; th[test2] colspan '1' rowspan '1'.
- `--last` ths: exactly age and test2 (querySelectorAll('.n-data-table-th--last')
  length 2, data-col-keys age/test2).
- colgroup col count 3; col[1]/col[2] (test1/test2, widthless)
  `hasAttribute('style') === false`; col[0] width:100px;min-width:100px.
- th[age] (group, w100) style contains 'width:100px'.
- Body rows: 3 tds each (name/test1/test2 data-col-keys); body td for 'age'
  key does NOT exist.

P5 merge + expand: expand column + name(colSpan i==0?2:1) → expand-row td
colspan === leaf count (2).
