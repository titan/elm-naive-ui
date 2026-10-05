# BRIEF — date-time engine — feeds feat(date-picker), Task 3

Workspace: /home/titan/Works/elm/elm-naive-ui. WRITE SCOPE: exactly ONE workspace file, /home/titan/Works/elm/elm-naive-ui/src/NUI/Internal/DateTime.elm (new, unexposed). To avoid elm-stuff lock contention with the verify gate running in the main workspace: copy the workspace to /tmp/nui-engine (`cp -r`), do ALL writing + compilation under /tmp/nui-engine (`ELM_HOME=/tmp/elm-home elm make src/NUI/Internal/DateTime.elm --output=/dev/null`), and only when clean + elm-formatted, copy the finished file to the workspace path. No other workspace writes. NO commit.

CURRENT STATE (verified): /tmp/nui-engine already exists (elm-stuff initialized, Loading.elm present); DateTime.elm does not exist anywhere yet.

## Spec sources (authoritative, in order)
- /home/titan/Works/elm/naive-ui/src/date-picker/src/utils.ts — dateItem/weekItem/monthItem/quarterItem/yearItem (:149-350), dateArray (:351-418), monthArray/quarterArray/yearArray (:420-478), strictParse (:480-494), getDefaultTime/extractSingleDefaultTime/extractRangeDefaultTime (:496-548), pluckValueFromRange (:549-554). /home/titan/Works/elm/naive-ui/src/time-picker/src/utils.ts — time unit lists.
- date-fns v2 SOURCE (port algorithms from here): /home/titan/Works/elm/naive-ui/node_modules/date-fns/esm/ — format/_lib/format/{formatters,index}.js; parse/_lib/parse/{parsers,index}.js + setters; getWeek; getWeekYear; startOfWeek; startOfDay/Month/Year/Quarter/Second; addMonths; setYear/setMonth/setDate/setHours/setMinutes/setSeconds/setQuarter; isSameMonth/Year/Quarter.
- Elm precedents: /home/titan/Works/elm/elm-naive-ui/src/NUI/Calendar.elm :427-560 (Hinnant daysFromCivil/civilFromDays/addDays/weekday/daysInMonth) and src/NUI/Heatmap.elm :1018-1171 (toCivil, weekStartOn (x+1)%7, converge — civil→Posix in a Time.Zone).
- Semantics map: tasks/recon/date-picker-2-single.md §2 (item model + dateArray padding + sanitizeValue), -3-root.md §4 (utils + firstDayOfWeek transform), -4-range.md (span flags + dual arrays), -5-elm.md §1+§9.

## Module shape (exported names pinned — DatePicker + tests build on them)
```elm
module NUI.Internal.DateTime exposing (..)   -- explicit export list; elm/time + elm/core only
type alias Civil = { year : Int, month : Int, day : Int }          -- month 1-12
toCivil : Time.Zone -> Int -> Civil
toTimeFields : Time.Zone -> Int -> { hours : Int, minutes : Int, seconds : Int, ms : Int }
toPosix : Time.Zone -> Civil -> { hours : Int, minutes : Int, seconds : Int, ms : Int } -> Int   -- converge idiom
daysFromCivil : Civil -> Int
civilFromDays : Int -> Civil
addDays : Int -> Int -> Int            -- on ts? NO: civil-level helpers operate on Civil; ts-level ops take Zone
weekday : Civil -> Int                 -- date-fns getDay 0=Sun
daysInMonth : Int -> Int -> Int        -- year, month
addMonthsClamped : Int -> Civil -> Civil
addYearsClamped : Int -> Civil -> Civil
startOfDay : Time.Zone -> Int -> Int
startOfMonth : Time.Zone -> Int -> Int
startOfYear : Time.Zone -> Int -> Int
startOfQuarter : Time.Zone -> Int -> Int
startOfSecond : Time.Zone -> Int -> Int
quarterOf : Time.Zone -> Int -> Int    -- 1-4
setFields : Time.Zone -> Int -> { year : Maybe Int, month : Maybe Int, day : Maybe Int, hours : Maybe Int, minutes : Maybe Int, seconds : Maybe Int, quarter : Maybe Int } -> Int   -- date-fns set* semantics; Feb29 clamps
type Granularity = DateGran | MonthGran | YearGran | QuarterGran | WeekGran
matchDate : Granularity -> Int -> Int -> Bool
firstDayOfWeekToDateFns : Int -> Int   -- (x+1)%7 naive 0=Mon → date-fns 0=Sun
startOfWeekOn : Int -> Time.Zone -> Int -> Int
startOfWeek : Time.Zone -> Int -> Int  -- weekStartsOn 0
weekNumber : Int -> Time.Zone -> Int -> Int   -- date-fns getWeek(weekStartsOn, firstWeekContainsDate=4) port
weekYear : Int -> Time.Zone -> Int -> Int     -- date-fns getWeekYear ('YYYY')
type ValueTs = NoValue | SingleTs Int | RangeTs Int Int
type alias DateItem = { dateObject : Civil, inCurrentMonth : Bool, isCurrentDate : Bool, inSpan : Bool, startOfSpan : Bool, endOfSpan : Bool, selected : Bool, inSelectedWeek : Bool, ts : Int }
dateArray : Int -> ValueTs -> Int -> Int -> Bool -> Bool -> List DateItem  -- startDay(date-fns numbering), valueTs, nowTs, strip, weekMode; 42 cells when not strip (utils.ts :351-418 incl. the protectLastMonthDateIsShownFlag guard)
monthArray : Int -> ValueTs -> Int -> { monthFormat : String } -> List MonthItem      -- MonthItem = { type, dateObject {year,month}, ts, isCurrent, selected, monthFormat }
quarterArray : Int -> ValueTs -> Int -> { quarterFormat : String } -> List QuarterItem
yearArray : ValueTs -> Int -> { yearFormat : String } -> ( Int, Int ) -> List YearItem    -- yearRange; range[1]-range[0] items
format : String -> Time.Zone -> Int -> String     -- tokens: yy yyyy M MM MMM MMMM d dd H HH h hh K k m mm s ss Q qqq w YYYY a; '..quoted literal..' + '' escape; unknown chars pass through; en-US names baked (MMM Jan..Dec, MMMM full, eee Sun..Sat, eeee full, eeeeee Su.., qqq Q1..Q4, a AM/PM)
strictParse : String -> String -> Time.Zone -> Maybe Int    -- parse the token subset (lenient numeric widths, names by unique prefix) + round-trip format equality else Nothing
getDefaultTime : Maybe String -> Maybe { hours : Int, minutes : Int, seconds : Int }      -- 'HH:mm:ss' split
extractRangeDefaultTime : String -> String -> { start : Maybe { hours : Int, minutes : Int, seconds : Int }, end : Maybe { hours : Int, minutes : Int, seconds : Int } }  -- two static slots (upstream fn-form punted — document)
pluckValueFromRange : ValueTs -> Int -> Maybe Int    -- 0=start 1=end
```
All timestamps Int ms; civil interpretation always via the caller-supplied Time.Zone. Docstring head documents every deviation (fn-form DefaultTime punted; parse subset limited to the token list; anything else fails strictParse round-trip → Nothing). elm-format the file.

Tool hygiene: repeat-call guard KILLS sessions — batch reads, vary queries, never re-run an identical command verbatim back-to-back.
