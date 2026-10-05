# Brief — split Main.elm's 87 static sections into Sections/* family modules

You are in a git worktree of `/home/titan/Works/elm/elm-naive-ui` (master @
85d567e). One module of the split is YOURS (named in your spawn prompt). You
create exactly ONE new file `examples/src/Sections/<Name>.elm`, verify it
compiles + is elm-format clean, copy it to `/tmp/sections-<Name>.elm`, and
report. You do NOT touch Main.elm or any other repo file, and you do NOT
commit. The orchestrator wires all modules into Main.elm afterwards.

## Why / what stays invariant

`examples/src/Main.elm` (5,808 L) holds 87 static `xxxSection : Element msg`
functions that feed the check-dom gate (100 component roots). They are being
moved, VERBATIM, into eight family modules under `examples/src/Sections/`.
The rendered DOM must stay byte-identical — so: no renaming, no reordering,
no "improvements", bodies copied exactly (elm-format may reflow whitespace
only). Interactivity (Live/*) stays in Main.

## Module assignments

| Module | Sections (function names in Main.elm — grep `^name :`) |
| --- | --- |
| Sections.General | typographySection tagSection alertSection dividerSection avatarSection cardSection spaceSection badgeSection emptySection resultSection gradientTextSection statisticSection thingSection iconSection highlightSection ellipsisSection rtlSection themeSection |
| Sections.Display | breadcrumbSection timelineSection listSection pageHeaderSection affixSection flexSection gridSection qrCodeSection heatmapSection descriptionsSection scrollbarSection watermarkSection floatButtonSection floatButtonGroupSection layoutSection codeSection equationSection |
| Sections.Controls | buttonSection inputSection inputOtpSection inputNumberSection selectionSection rateSection sliderSection |
| Sections.Nav | tabsSection collapseSection menuSection paginationSection stepsSection anchorSection backTopSection splitSection |
| Sections.Data | dataTableSection tableSection treeSection transferSection calendarSection imageSection imagePreviewSection uploadSection dynamicInputSection dynamicTagsSection |
| Sections.Motion | carouselSection logSection countdownSection numberAnimationSection progressSection spinSection skeletonSection marqueeSection |
| Sections.Overlays | dropdownSection popoverSection popconfirmSection tooltipSection modalSection drawerSection dialogSection messageSection notificationSection loadingBarSection |
| Sections.Pickers | selectSection popselectSection cascaderSection treeSelectSection autoCompleteSection mentionSection datePickerSection timePickerSection colorPickerSection |

## How to build your module

1. **Sections verbatim.** Copy each of your sections from Main.elm exactly
   (including their docstring comments if any). Function names, ids, demo
   labels, option values — untouched.
2. **Section-local top-level helpers travel WITH their section.** Main.elm
   defines non-section top-level values next to the sections (e.g.
   `heatmapSample`, `popoverHost`, `selectOptions`, `tableContent`,
   `treeOptions`, `menuOpts`, `imageLogo`, `dialogState`, `messageOf` …) and
   a big DEFAULTS block (`btn`, `typ`, `tagD`, `inputD`, … one-liners over
   `X.defaults`) plus data like `tabsItems`. Copy EVERY top-level binding
   your sections (or their helpers) reference into your module, verbatim,
   same names. Two bindings with the same name in different modules is fine —
   they are pure literal records. The compiler is your safety net: build
   until zero NAMING/MISSING errors, then grep Main.elm for any identifier
   you might have silently re-derived instead of copied.
3. **From Showcase, import — never copy:** `theme`, `purple`, `darkTheme`,
   `section`, `demoRow`, `chip`, `capitalize`, `starIcon`, `codeHljs`,
   `fakeKatex`, `fakeKatexDisplay` (the last four were just moved there;
   `starIcon` is used by icon+menu sections, `codeHljs` by code+log, the
   katex pair by equation).
   `import Showcase exposing (...)` with exactly the names you use.
4. **Imports:** what your bodies need — `Element` (+ `Element.Background as
   Bg`, `Element.Font as Font`, `Element.Border as Border` where used),
   `Html`, `Html.Attributes as HA`, `Html.Events as HE`, `Json.Decode as
   Decode`, `Time`, and the `NUI.*` modules your sections drive. Only what
   you use — no unused imports.
5. **Module header:**
   ```elm
   module Sections.<Name> exposing (…)  -- exactly your section functions

   {-| Static showcase sections for the <family description> family, moved
   verbatim from Main.elm — the rendered DOM must stay byte-identical (the
   check-dom gate reads this surface).
   -}
   ```
   Expose ONLY the section functions (helpers stay module-private).
6. Sections are `Element msg` (msg-polymorphic) — keep the exact signatures.

## Verify before reporting

```bash
cd examples && ELM_HOME=/tmp/elm-home elm make src/Sections/<Name>.elm --output=/dev/null; echo $?
# TRAP: elm make progress is \r-overwritten — judge ONLY by the exit code.
elm-format --yes examples/src/Sections/<Name>.elm
# re-run the make once more after formatting.
cp examples/src/Sections/<Name>.elm /tmp/sections-<Name>.elm
git status   # must show ONLY the new untracked file
```

## Report back

- Module path + `/tmp` copy path, line count, section count.
- The list of extra top-level bindings you copied (names only).
- Anything you had to adapt beyond verbatim copy (there should be nothing —
  if the compiler forced a change, describe it precisely).
