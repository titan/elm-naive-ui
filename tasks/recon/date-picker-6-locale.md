# Locale defaults pinned — naive-ui v2.45.3 `src/locales/common/enUS.ts`

## DatePicker (`:23-53`)
```
yearFormat: 'yyyy'
monthFormat: 'MMM'
dayFormat: 'eeeeee'
yearTypeFormat: 'yyyy'
monthTypeFormat: 'yyyy-MM'
dateFormat: 'yyyy-MM-dd'
dateTimeFormat: 'yyyy-MM-dd HH:mm:ss'
quarterFormat: 'yyyy-qqq'
weekFormat: 'YYYY-w'
clear: 'Clear'
now: 'Now'
confirm: 'Confirm'
selectTime: 'Select Time'
selectDate: 'Select Date'
datePlaceholder: 'Select Date'
datetimePlaceholder: 'Select Date and Time'
monthPlaceholder: 'Select Month'
yearPlaceholder: 'Select Year'
quarterPlaceholder: 'Select Quarter'
weekPlaceholder: 'Select Week'
startDatePlaceholder: 'Start Date'
endDatePlaceholder: 'End Date'
startDatetimePlaceholder: 'Start Date and Time'
endDatetimePlaceholder: 'End Date and Time'
startMonthPlaceholder: 'Start Month'
endMonthPlaceholder: 'End Month'
monthBeforeYear: true
firstDayOfWeek: 6        // 0 | 1 | ... | 6  (Naive numbering: 0 = Monday)
today: 'Today'
```

## TimePicker (`:77-83`)
```
placeholder: 'Select Time'
positiveText: 'OK'
negativeText: 'Cancel'
now: 'Now'
clear: 'Clear'
```

## Format-engine token requirements implied
- `yyyy`, `MM`, `dd`, `HH`, `mm`, `ss` (defaults) — required.
- `MMM` (calendar month header → "Jan".."Dec"; Heatmap default labels already carry these).
- `eeeeee` (weekday head labels → date-fns enUS min two-letter: "Su","Mo","Tu","We","Th","Fr","Sa"; ORDER follows dateArray head = weekStartsOn-shifted).
- `qqq` (quarter → "Q1".."Q4"); props default `quarterFormat: "'Q'Q"` → literal `Q` + quarter number ("Q1").
- `YYYY-w` (week type display: local week-numbering year + local week of year — needs week math with `weekStartsOn`).
- props defaults `monthFormat: 'M'`, `yearFormat: 'y'` (scroll-col labels "1".."12", "1901".."2100").
- TimePicker `format: 'HH:mm:ss'` default + user tokens: `H,h,K,k` (+doubled), `m`, `s`, literals in `'…'`; `/H|h|K|k/` presence gates the hour col, `'m'` the minute col, `'s'` the second col.
