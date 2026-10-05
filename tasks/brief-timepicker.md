# BRIEF — feat(time-picker) — Task 2 of the TimePicker/DatePicker batch

Workspace: /home/titan/Works/elm/elm-naive-ui (branch master, commit directly, use_worktree=false).
READ FIRST (in this order):
1. tasks/recon/date-picker-6-input.md  — Input.tsx focus seams + suffix/clear-icon-placeholder bytes; "Elm seam implications" tail section is the seam spec.
2. tasks/recon/date-picker-1-time.md   — TimePicker spec: trigger DOM (§a), panel DOM (§b), pure utils (§c), cssVars orders (§a), actions defaults (§b).
3. tasks/recon/date-picker-5-elm.md    — Elm conventions: §3 view/menu split + focusDetector idiom, §4 theme pipeline, §8 examples/tests structure.
Templates to mirror: src/NUI/AutoComplete.elm (plain-Input trigger), src/NUI/TreeSelect.elm (view/menu + focusDetectorNode + transition), src/NUI/Calendar.elm (inline Svg glyph), src/NUI/Input.elm (extended by you).

CURRENT STATE (verified by orchestrator): src/NUI/Input.elm is MODIFIED (913 L) — a previous lane's PARTIAL, UNVERIFIED seam work. TimePicker.elm does not exist. Examples/README/elm.json/check-dom untouched. No commit. Start by READING the Input.elm diff (`git diff src/NUI/Input.elm`), fix/complete the seams per spec below, keep them default-off (existing single-input bytes must not change — the gate regression-pins them).

## Deliverable 1 — src/NUI/Input.elm ADDITIVE seams (default-off)
- `passivelyActivated : Bool` + `activated : Bool` (caller-owned): root `tabindex 0` iff passivelyActivated && not activated && not disabled; inner input `tabindex -1` iff passivelyActivated && not activated.
- `internalForceFocus : Bool` → adds `n-input--focus` root class (ONLY new root class; upstream has no --active/--hover classes).
- `textDecoration : Maybe String` → inline `text-decoration` on the input element.
- `attrSize : Maybe Int` → `size` attribute on the input element (upstream default 20; only when Just).
- `onFocus : Maybe msg` / `onBlur : Maybe msg` → raw focus/blur events on the input element.
- `clearIconPlaceholder : Maybe (Element msg)` → when clearable + set: placeholder content shown where the clear icon hides (NBaseClear placeholder slot, recon-6 §5). Align with the existing clear implementation; extend additively where it diverges, note in a comment.
- Do NOT: pair mode (date-picker lane), Enter/Esc activation, programmatic focus (caller-owned — short comment).

## Deliverable 2 — src/NUI/TimePicker.elm (new, ~700 L)
Module docstring head: ported surface + documented punts (scroll-to-active scrollTimer; IANA timeZone prop — Time.Zone caller-supplied; memorizedValue auto-restore caller-owned; panel Tab handled by focusDetector sentinel; Enter/Esc activation caller-owned).

Pinned API:
```elm
type TimeAction = Clear | Now | Confirm
type UnitFilter = AllUnits | StepUnits Int | OnlyUnits (List Int)
type alias Options msg =
    { value : Maybe Int, text : Maybe String, onInput : Maybe (String -> msg)
    , onUpdateValue : Maybe (Maybe Int -> msg), onUpdateFormattedValue : Maybe (Maybe String -> msg)
    , onUpdateShow : Maybe (Bool -> msg), onClear : Maybe msg, onConfirm : Maybe msg
    , onFocus : Maybe msg, onBlur : Maybe msg
    , show : Bool, format : String, use12Hours : Bool, placeholder : String
    , size : <Input's Size>, bordered : Bool, clearable : Bool
    , status : Maybe <Input's Status>, disabled : Bool, inputReadonly : Bool, showIcon : Bool
    , actions : List TimeAction, hours : UnitFilter, minutes : UnitFilter, seconds : UnitFilter
    , isHourDisabled : Maybe (Int -> Bool)
    , isMinuteDisabled : Maybe (Int -> Maybe Int -> Bool)
    , isSecondDisabled : Maybe (Int -> Maybe Int -> Maybe Int -> Bool)
    , zone : Time.Zone, now : Time.Posix
    , transition : Maybe <Internal TransitionPhase>, iconNode : Maybe (Element msg)
    }
defaultOptions : Options msg                          -- format 'HH:mm:ss', placeholder 'Select Time', actions [Now,Confirm], showIcon True, bordered True
view : Theme -> Options msg -> Element msg            -- div.n-time-picker + triggerThemeClass + 3 triggerCssVars exact order + Input(seams) + icon branch (clearable → clearIconPlaceholder else suffix; i.n-base-icon + class n-time-picker-icon + Time glyph)
panel : Theme -> Options msg -> Element msg           -- div.n-time-picker-panel (tabindex 0) + 14 panelCssVars exact order + transition class + cols + actions + focusDetector last child
formatValue : String -> Time.Zone -> Int -> String    -- date-fns subset tokens H HH h hh K k m mm s ss a + quoted literals + pass-through
parseInput : String -> Time.Zone -> String -> Maybe Int  -- strictParse: parse then round-trip format equality else Nothing
snapNow : String -> Time.Zone -> Time.Posix -> UnitFilter -> UnitFilter -> UnitFilter -> Int  -- findSimilarTime per visible unit (time-picker utils.ts :248-277; ties → lower bound)
```
Panel internals (recon-1 §b): `div.n-time-picker-cols` > per visible unit (`showHour = Regex /H|h|K|k/ test on format`, `showMinute = includes "m"`, `showSecond = includes "s"`, plus use12Hours period col) → `div.n-time-picker-col` (+ `--invalid` iff that unit's current value is disabled, + `--transition-disabled` per transition phase) > NUI.Scrollbar.view > items (`div.n-time-picker-col__item`, attribute `data-active ""` iff active, classes `--active`/`--disabled`, label = 2-char padded unit strings / AM/PM) + `div.n-time-picker-col__padding`. Item click → onUpdateValue (pure: set that unit on value||now base). Actions row iff actions non-empty: NUI.Button size tiny each; confirm adds type primary + class `n-time-picker-actions__confirm` + disabled iff isValueInvalid (pure: any visible unit's current value disabled). Time glyph: inline Svg.node, copy path data from /home/titan/Works/elm/naive-ui/src/_internal/icons/Time.tsx.
Theme: NUI.Theme.TimePicker generated in prep commit 138f844 — wire it into the aggregate Theme record exactly the way tree-select's prep+feat pair did (check src/NUI/Theme.elm + how TreeSelect.view consumes it).

## Deliverables 3-6
3. examples/src/Main.elm — `timePickerSection` (mirror treeSelectSection; view + inline panel; cover default HH:mm:ss, HH:mm, use12Hours, actions [Clear,Now,Confirm], disabled-unit validators, size/clearable/disabled) + register in the section list.
4. README.md — row `| NUI.TimePicker | ✅ |`.
5. elm.json — expose NUI.TimePicker.
6. tools/verify/check-dom.mjs — targets `'.n-time-picker': false, '.n-time-picker-panel': true` (mirror tree-select lines).

## Validation + commit
elm-format every touched .elm file, then `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` (8 gates, all green; includes 3464-assertion test suite — Input regressions will fail check-dom/DOM pins if your seams aren't default-off). Commit `feat(time-picker): Input focus seams + trigger + caller-mounted cols panel` with EXPLICIT paths only (never `git add -A`; tasks/ stays untracked).
Note: another lane compiles under /tmp/nui-engine — do not touch /tmp; if elm-stuff lock errors occur, sleep 30s and retry.

Tool hygiene: a repeat-call guard KILLS sessions issuing identical repeated tool calls — batch reads, vary queries, never re-run an identical command verbatim back-to-back.
