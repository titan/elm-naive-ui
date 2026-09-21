module NUI.Form exposing
    ( Align(..)
    , Feedback
    , ItemOptions
    , LabelWidth(..)
    , Level(..)
    , Options
    , Placement(..)
    , RequireMarkPlacement(..)
    , Rule
    , RuleType(..)
    , Rules
    , Size(..)
    , Trigger(..)
    , Value(..)
    , Values
    , cssVarsForItem
    , defaultRule
    , defaults
    , isRequired
    , item
    , itemDefaults
    , validateForm
    , validateValue
    , view
    )

{-| Naive UI's `Form` + `FormItem`, rebuilt on elm-ui: a pure validation engine
plus the two views.

    import NUI.Form as Form exposing (Value(..))

    -- rules (upstream `rules` on the NFormItem)
    nameRules =
        [ { Form.defaultRule | required = True, message = Just "Name is required" }
        , { Form.defaultRule | min = Just 2, message = Just "Too short" }
        ]

    -- the item: the value is passed in already validated (see the recipe below)
    Form.item theme
        { Form.itemDefaults
            | label = Just "Name"
            , feedback = Just (String.join " " (List.map .message model.nameFeedback))
            , validation = Just model.nameFeedback
        }
        [ NUI.Input.view theme { NUI.Input.defaults | value = model.name } ]

The module has the same split as `NUI.Countdown` / `NUI.LoadingBar`: a **pure
engine** (`validateValue` / `validateForm` / `isRequired`) that returns
`Feedback`s, and the views (`view` = the `form.n-form`, `item` = one
`n-form-item`) which render what the engine produced. Upstream keeps validation
state inside the form item and validates as a side effect; here the caller owns
it — state lives in your model and transitions through your `update`.

**The caller-owned validation recipe** (upstream's blur/change wiring, made
explicit). Upstream's `NFormItem` subscribes to its child input's
`update:value` / `blur` / `focus` events and runs the matching `trigger`ed
rules, writing the result into internal state. A pure port has no such channel,
so you wire it:

1.  the input's events become `Msg`s you already own (`onInput`, `onBlur`, …);
2.  in `update`, call `validateValue (Just trigger) field rules (Just value)`
    — `OnBlur` from a blur `Msg`, `OnChange` from a change `Msg`, `Nothing` for
    a manual submit-time validate of every rule;
3.  store the returned `List Feedback` in your model (e.g.
    `{ model | nameFeedback = feedback }`);
4.  pass it back down as `ItemOptions.validation`; the item renders the
    messages and resolves the status from them.

Because the engine is pure, this composes with anything (debounce, async
lookups, cross-field rules) without a registry or provide/inject.

**Markup divergences** (DOM details the port cannot reproduce exactly):

  - `view` returns a real `<form class="n-form">`, but its children are
    `Element`s and elm-ui has no public `Element` → `Html` conversion, so each
    child is embedded through `Element.layoutWith` (with
    `Element.noStaticStyleSheet`, so the per-child _static_ stylesheet is not
    re-emitted — only elm-ui's small dynamic font sheet remains; see the note
    on `embedChild`) — a wrapper `div` carrying elm-ui's root styles. The
    wrapper gets an inline `display: contents` (so the child participates
    directly in the form's flex/grid) and inline `font` / `color: inherit`
    (best-effort neutralisation of elm-ui's class-based root font; jsdom drops
    the `font` shorthand from the serialised attribute). This mirrors
    `NUI.DynamicInput`'s pair-input wrapper: geometry preserved, one extra DOM
    node per child.

  - `item` / its label / blank / feedback wrapper are built in elm-ui /
    `Element.html` land. The item root and the blank are elm-ui elements whose
    flex scaffolding (`display: flex`) would normally fight the extracted
    stylesheet; as everywhere in this library the doubled `.nui-root.nui-root`
    scoping wins (`.n-form-item { display: grid }`), and the label / feedback
    wrapper are raw `Html` nodes so the exact tag and class strings survive.

  - `onSubmit` maps to `Html.Events.onSubmit` with **no** implicit
    `preventDefault` — upstream calls `event.preventDefault()` itself; here the
    caller decides (return a `Msg` that re-renders, or none).

**Divergences** (engine / API only; documented, not accidental):

  - the engine is the port of async-validator@4.2.5's exercised subset. Not
    ported: `asyncValidator`, `transform`, `defaultField` / nested fields,
    `renderMessage`, `first`, nested rule trees, the `validateMessages`
    override, and the `url` / `email` / `date` / `method` / `regexp` /
    `integer` / `float` / `object` / `hex` types (and `pattern`-as-a-type).

  - no form-item registry and no provide/inject cascade: the item's `size`,
    `disabled`, `showLabel`, `showFeedback`, … are not inherited from a parent
    form, no input is told to validate on blur/change, there is no path
    watch/restore and no `ignorePathChange`. `validateForm` is the pure analog
    of upstream's `form.validate`.

  - `pattern` uses elm/regex; an **uncompilable** source makes the rule FAIL
    with `rule.message` (fallback `"Validation error on field %s"`) instead of
    upstream's runtime throw — fail loudly, in band.

  - `LabelWidth` has no `'auto'` (upstream measures the widest child label in
    the DOM); only `Px Int` / `Custom String` are ported.

  - the success validation status is not ported (`success` feedback styling);
    `level` is `ErrorLevel` / `WarningLevel` only.

  - the `feedback` / `label` **slots** are not ported (`feedback : Maybe String`
    and `label : Maybe String` cover the string forms), `labelProps` beyond
    `for` are not ported, and the deprecated `FormItemRow` / `FormItemCol` /
    `FormItemGridItem` components have no counterpart.

  - the fade-down transition between feedback states exists in the stylesheet
    but is **not driven** — the port swaps instantly. As an optional upgrade,
    the caller can own the phase: keep the previous feedback, render the
    outgoing lines under `"fade-down-transition-leave-active"` for one frame via
    `NUI.Internal.transitionClass "fade-down-transition"`, then mount the new
    lines under the enter classes (exactly the caller-driven pattern of
    `NUI.LoadingBar`).

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Form as FormTheme
import Regex



-- ENGINE ----------------------------------------------------------------------


{-| A model field's value, the port's stand-in for async-validator's dynamic
`typeof` dispatch (upstream resolves values out of the model via lodash
`get`; here the caller maps fields to `Value`s).
-}
type Value
    = VString String
    | VNumber Float
    | VBool Bool
    | VArray (List Value)
    | VNull


{-| The `type` of an async-validator rule (the exercised subset; upstream's
`url` / `email` / `date` / `method` / `regexp` / `integer` / `float` /
`object` / `hex` are not ported). `TypeEnum` is upstream's
`{ type: 'enum', enum: [...] }`.
-}
type RuleType
    = TypeAny
    | TypeString
    | TypeNumber
    | TypeArray
    | TypeBoolean
    | TypeEnum


{-| Naive UI's rule `trigger` values.
-}
type Trigger
    = OnBlur
    | OnChange
    | OnFocus
    | OnInput


{-| Naive UI's rule `level` (`'warning'` rules surface as warnings and only
validate when the error-level rules are clean).
-}
type Level
    = ErrorLevel
    | WarningLevel


{-| One validation rule — async-validator's rule surface (the exercised
subset) plus naive-ui's `level`. `message = Just m` wins verbatim (no
interpolation); `validator = Just f` replaces all structural checks for its
rule.
-}
type alias Rule =
    { required : Bool
    , type_ : RuleType
    , min : Maybe Float
    , max : Maybe Float
    , len : Maybe Int
    , enum_ : List String
    , whitespace : Bool
    , pattern : Maybe String
    , message : Maybe String
    , trigger : Maybe (List Trigger)
    , level : Level
    , validator : Maybe (Value -> Bool)
    }


defaultRule : Rule
defaultRule =
    { required = False
    , type_ = TypeString
    , min = Nothing
    , max = Nothing
    , len = Nothing
    , enum_ = []
    , whitespace = False
    , pattern = Nothing
    , message = Nothing
    , trigger = Nothing
    , level = ErrorLevel
    , validator = Nothing
    }


{-| One failed rule: its level and rendered message.
-}
type alias Feedback =
    { level : Level
    , message : String
    }


{-| Rules keyed by path (upstream's `FormRules` flattened — nested rule
trees are not ported).
-}
type alias Rules =
    List ( String, List Rule )


{-| Values keyed by path — the caller's model mapped to `Value`s (first
match wins).
-}
type alias Values =
    List ( String, Value )


{-| Validate one field's rules against one value.

`trigger` is the event that fired: `Nothing` is a manual validate and runs
**every** rule; `Just t` runs only rules whose `trigger` list contains `t`
(a rule with `trigger = Nothing` is dropped under a passed trigger — upstream's
`rule.trigger === trigger` is false for `undefined`). `field` is
interpolated into the messages. `value = Nothing` is an absent field.

Error-level rules are evaluated first; if any error feedback is produced the
warnings are dropped, otherwise the warning feedbacks are returned. Order is
preserved within each level.

-}
validateValue : Maybe Trigger -> String -> List Rule -> Maybe Value -> List Feedback
validateValue trigger field rules value =
    let
        active =
            case trigger of
                Nothing ->
                    rules

                Just t ->
                    List.filter (matchesTrigger t) rules

        errors =
            active
                |> List.filter (\rule -> rule.level == ErrorLevel)
                |> List.concatMap (ruleFeedback field value)

        warnings =
            active
                |> List.filter (\rule -> rule.level == WarningLevel)
                |> List.concatMap (ruleFeedback field value)
    in
    if List.isEmpty errors then
        warnings

    else
        errors


matchesTrigger : Trigger -> Rule -> Bool
matchesTrigger t rule =
    case rule.trigger of
        Just list ->
            List.member t list

        Nothing ->
            False


{-| Validate every (filtered) rule path — the pure analog of upstream's
`form.validate`. Each path in `rules` (restricted to `paths` when given, kept
in `rules` order) is emitted with its feedback list — empty when the path is
valid. Values are looked up first-match-wins; a path with no value is absent.
-}
validateForm : Maybe Trigger -> Maybe (List String) -> Rules -> Values -> List ( String, List Feedback )
validateForm trigger paths rules values =
    rules
        |> List.filter
            (\( path, _ ) ->
                case paths of
                    Nothing ->
                        True

                    Just keep ->
                        List.member path keep
            )
        |> List.map
            (\( path, fieldRules ) ->
                ( path, validateValue trigger path fieldRules (lookupValue path values) )
            )


lookupValue : String -> Values -> Maybe Value
lookupValue path values =
    values
        |> List.filter (\( p, _ ) -> p == path)
        |> List.head
        |> Maybe.map Tuple.second


{-| Upstream's `mergedRequired` (rules side): any rule has `required = True`.
-}
isRequired : List Rule -> Bool
isRequired rules =
    List.any .required rules


{-| One rule's feedback. A rule with a `validator` uses only that function
(invoked for every value, absent ones as `VNull`); a false result yields
`rule.message` verbatim, falling back to `field ++ " fails"`. Otherwise the
structural checks run, and a failing rule with `message = Just m` collapses its
whole error list to the single verbatim `m`.
-}
ruleFeedback : String -> Maybe Value -> Rule -> List Feedback
ruleFeedback field value rule =
    case rule.validator of
        Just validate ->
            if validate (Maybe.withDefault VNull value) then
                []

            else
                [ { level = rule.level
                  , message = Maybe.withDefault (field ++ " fails") rule.message
                  }
                ]

        Nothing ->
            case structuralMessages field rule value of
                [] ->
                    []

                messages ->
                    case rule.message of
                        Just m ->
                            [ { level = rule.level, message = m } ]

                        Nothing ->
                            List.map (\m -> { level = rule.level, message = m }) messages


{-| The built-in checks for one (non-custom) rule, in order: required → type →
range → pattern → whitespace (last two string-only; the last three per type).
-}
structuralMessages : String -> Rule -> Maybe Value -> List String
structuralMessages field rule value =
    let
        effective =
            case rule.type_ of
                TypeNumber ->
                    coerceNumber value

                _ ->
                    value
    in
    if skipStructural rule effective then
        []

    else
        let
            requiredMessages =
                if rule.required && isEmptyValue rule.type_ effective then
                    [ field ++ " is required" ]

                else
                    []
        in
        if not (List.isEmpty requiredMessages) then
            requiredMessages

        else
            checkMessages field rule effective


{-| Whether the whole rule is skipped because the value is empty and the rule
is not required. For an array the ONLY skip is an absent value — `VArray []`
runs the type + range checks (an empty array under `min` reports its length).
The caller has already applied the number `''` → absent coercion.
-}
skipStructural : Rule -> Maybe Value -> Bool
skipStructural rule value =
    if rule.required then
        False

    else
        case rule.type_ of
            TypeArray ->
                isNullish value

            TypeEnum ->
                value == Nothing

            TypeString ->
                isEmptyValue TypeString value

            TypeNumber ->
                isEmptyValue TypeNumber value

            TypeBoolean ->
                isNullish value

            TypeAny ->
                isNullish value


checkMessages : String -> Rule -> Maybe Value -> List String
checkMessages field rule value =
    case rule.type_ of
        TypeAny ->
            []

        TypeString ->
            typeMessages field rule value
                ++ rangeMessages field rule value
                ++ patternMessages field rule value
                ++ whitespaceMessages field rule value

        TypeNumber ->
            typeMessages field rule value ++ rangeMessages field rule value

        TypeBoolean ->
            case value of
                Nothing ->
                    []

                _ ->
                    typeMessages field rule value

        TypeArray ->
            typeMessages field rule value ++ rangeMessages field rule value

        TypeEnum ->
            enumMessages field rule value


{-| `''` under a number rule behaves as an absent value (upstream coerces
`value === ''` to `undefined` before the emptiness test).
-}
coerceNumber : Maybe Value -> Maybe Value
coerceNumber value =
    case value of
        Just (VString "") ->
            Nothing

        other ->
            other


isNullish : Maybe Value -> Bool
isNullish value =
    value == Nothing || value == Just VNull


{-| async-validator's `isEmptyValue(value, type)`: `null` / `undefined`, an
empty array under an array rule, an empty string under a string rule.
-}
isEmptyValue : RuleType -> Maybe Value -> Bool
isEmptyValue ruleType value =
    case value of
        Nothing ->
            True

        Just VNull ->
            True

        Just (VArray []) ->
            ruleType == TypeArray

        Just (VString "") ->
            ruleType == TypeString

        _ ->
            False


typeMessages : String -> Rule -> Maybe Value -> List String
typeMessages field rule value =
    if valueMatchesType rule.type_ value then
        []

    else
        [ field ++ " is not " ++ typeArticle rule.type_ ++ typeName rule.type_ ]


valueMatchesType : RuleType -> Maybe Value -> Bool
valueMatchesType ruleType value =
    case ( ruleType, value ) of
        ( TypeAny, _ ) ->
            True

        ( TypeString, Just (VString _) ) ->
            True

        ( TypeNumber, Just (VNumber _) ) ->
            True

        ( TypeArray, Just (VArray _) ) ->
            True

        ( TypeBoolean, Just (VBool _) ) ->
            True

        ( TypeEnum, _ ) ->
            True

        _ ->
            False


typeName : RuleType -> String
typeName ruleType =
    case ruleType of
        TypeString ->
            "string"

        TypeNumber ->
            "number"

        TypeArray ->
            "array"

        TypeBoolean ->
            "boolean"

        _ ->
            ""


{-| Upstream's `types.array` message reads `"%s is not an %s"` — the only
family with the `an` article.
-}
typeArticle : RuleType -> String
typeArticle ruleType =
    if ruleType == TypeArray then
        "an "

    else
        "a "


{-| The `len` / `min` / `max` else-if cascade, dispatched by the value kind.
Boolean (and absent) values have no range and are skipped.
-}
rangeMessages : String -> Rule -> Maybe Value -> List String
rangeMessages field rule value =
    case value of
        Just (VNumber n) ->
            numberRange field rule n

        Just (VString s) ->
            stringRange field rule (correctedLength s)

        Just (VArray items) ->
            arrayRange field rule (List.length items)

        _ ->
            []


numberRange : String -> Rule -> Float -> List String
numberRange field rule n =
    case rule.len of
        Just l ->
            if n == toFloat l then
                []

            else
                [ field ++ " must equal " ++ String.fromInt l ]

        Nothing ->
            case ( rule.min, rule.max ) of
                ( Just mn, Nothing ) ->
                    if n < mn then
                        [ field ++ " cannot be less than " ++ String.fromFloat mn ]

                    else
                        []

                ( Nothing, Just mx ) ->
                    if n > mx then
                        [ field ++ " cannot be greater than " ++ String.fromFloat mx ]

                    else
                        []

                ( Just mn, Just mx ) ->
                    if n < mn || n > mx then
                        [ field ++ " must be between " ++ String.fromFloat mn ++ " and " ++ String.fromFloat mx ]

                    else
                        []

                ( Nothing, Nothing ) ->
                    []


stringRange : String -> Rule -> Int -> List String
stringRange field rule length =
    let
        l =
            toFloat length
    in
    case rule.len of
        Just n ->
            if length == n then
                []

            else
                [ field ++ " must be exactly " ++ String.fromInt n ++ " characters" ]

        Nothing ->
            case ( rule.min, rule.max ) of
                ( Just mn, Nothing ) ->
                    if l < mn then
                        [ field ++ " must be at least " ++ String.fromFloat mn ++ " characters" ]

                    else
                        []

                ( Nothing, Just mx ) ->
                    if l > mx then
                        [ field ++ " cannot be longer than " ++ String.fromFloat mx ++ " characters" ]

                    else
                        []

                ( Just mn, Just mx ) ->
                    if l < mn || l > mx then
                        [ field ++ " must be between " ++ String.fromFloat mn ++ " and " ++ String.fromFloat mx ++ " characters" ]

                    else
                        []

                ( Nothing, Nothing ) ->
                    []


arrayRange : String -> Rule -> Int -> List String
arrayRange field rule length =
    let
        l =
            toFloat length
    in
    case rule.len of
        Just n ->
            if length == n then
                []

            else
                [ field ++ " must be exactly " ++ String.fromInt n ++ " in length" ]

        Nothing ->
            case ( rule.min, rule.max ) of
                ( Just mn, Nothing ) ->
                    if l < mn then
                        [ field ++ " cannot be less than " ++ String.fromFloat mn ++ " in length" ]

                    else
                        []

                ( Nothing, Just mx ) ->
                    if l > mx then
                        [ field ++ " cannot be greater than " ++ String.fromFloat mx ++ " in length" ]

                    else
                        []

                ( Just mn, Just mx ) ->
                    if l < mn || l > mx then
                        [ field ++ " must be between " ++ String.fromFloat mn ++ " and " ++ String.fromFloat mx ++ " in length" ]

                    else
                        []

                ( Nothing, Nothing ) ->
                    []


{-| `enum` membership. The list is joined with `", "` (an empty list yields the
trailing-space message `"… must be one of "`, matching upstream's join of `[]`).
An empty string is a value here, so a non-required `""` still fails membership.
-}
enumMessages : String -> Rule -> Maybe Value -> List String
enumMessages field rule value =
    case value of
        Just (VString s) ->
            if List.member s rule.enum_ then
                []

            else
                [ field ++ " must be one of " ++ String.join ", " rule.enum_ ]

        Just _ ->
            [ field ++ " must be one of " ++ String.join ", " rule.enum_ ]

        Nothing ->
            []


{-| `pattern` is a source string compiled with elm/regex. A non-match reports
`field` + value + source; an uncompilable source fails the rule with the
default message instead of throwing.
-}
patternMessages : String -> Rule -> Maybe Value -> List String
patternMessages field rule value =
    case ( rule.pattern, value ) of
        ( Just source, Just (VString s) ) ->
            case Regex.fromString source of
                Nothing ->
                    [ "Validation error on field " ++ field ]

                Just regex ->
                    if Regex.contains regex s then
                        []

                    else
                        [ field ++ " value " ++ s ++ " does not match pattern " ++ source ]

        _ ->
            []


{-| `whitespace` is string-only: a non-empty all-whitespace value (JS
`/^\s+$/`) is rejected with `"%s cannot be empty"`.
-}
whitespaceMessages : String -> Rule -> Maybe Value -> List String
whitespaceMessages field rule value =
    if not rule.whitespace then
        []

    else
        case value of
            Just (VString s) ->
                if isAllWhitespace s then
                    [ field ++ " cannot be empty" ]

                else
                    []

            _ ->
                []


whitespaceRegex : Regex.Regex
whitespaceRegex =
    Regex.fromString "^\\s+$" |> Maybe.withDefault Regex.never


isAllWhitespace : String -> Bool
isAllWhitespace s =
    Regex.contains whitespaceRegex s


{-| JS `value.replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]/g, '_').length`: an
astral code point counts as one, not its two UTF-16 code units.
-}
surrogatePairRegex : Regex.Regex
surrogatePairRegex =
    Regex.fromString "[\\uD800-\\uDBFF][\\uDC00-\\uDFFF]"
        |> Maybe.withDefault Regex.never


correctedLength : String -> Int
correctedLength s =
    String.length (Regex.replace surrogatePairRegex (always "_") s)



-- VIEWS -----------------------------------------------------------------------


{-| The form item's size — drives the per-size theme vars.
-}
type Size
    = Small
    | Medium
    | Large


{-| `labelPlacement` (default `Top`).
-}
type Placement
    = Top
    | Left


{-| `labelAlign` (default `AlignLeft`).
-}
type Align
    = AlignLeft
    | AlignCenter
    | AlignRight


{-| `requireMarkPlacement` (default `MarkRight`).
-}
type RequireMarkPlacement
    = MarkLeft
    | MarkRight
    | MarkRightHanging


{-| `labelWidth` — a number (px) or a raw CSS width. Upstream's `'auto'`
(DOM measurement) is not ported.
-}
type LabelWidth
    = Px Int
    | Custom String


{-| Form options (`inline`, `onSubmit`).
-}
type alias Options msg =
    { inline : Bool
    , onSubmit : Maybe msg
    }


defaults : Options msg
defaults =
    { inline = False
    , onSubmit = Nothing
    }


{-| Form item options.
-}
type alias ItemOptions =
    { label : Maybe String
    , showLabel : Maybe Bool
    , labelFor : Maybe String
    , labelWidth : Maybe LabelWidth
    , labelAlign : Maybe Align
    , labelPlacement : Maybe Placement
    , labelStyle : Maybe String
    , required : Bool
    , showRequireMark : Maybe Bool
    , requireMarkPlacement : RequireMarkPlacement
    , showFeedback : Bool
    , size : Size
    , feedback : Maybe String
    , validation : Maybe (List Feedback)
    , validationStatus : Maybe Level
    , feedbackClass : Maybe String
    , feedbackStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    }


itemDefaults : ItemOptions
itemDefaults =
    { label = Nothing
    , showLabel = Nothing
    , showRequireMark = Nothing
    , labelFor = Nothing
    , labelWidth = Nothing
    , labelAlign = Nothing
    , labelPlacement = Nothing
    , labelStyle = Nothing
    , required = False
    , requireMarkPlacement = MarkRight
    , showFeedback = True
    , size = Medium
    , feedback = Nothing
    , validation = Nothing
    , validationStatus = Nothing
    , feedbackClass = Nothing
    , feedbackStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    }


{-| The `form.n-form` wrapper — a real `<form>`, children verbatim, `onSubmit`
when set.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts children =
    Element.html
        (Html.form
            (formAttrs opts)
            (List.map embedChild children)
        )


formAttrs : Options msg -> List (Html.Attribute msg)
formAttrs opts =
    [ HA.class (String.join " " ("n-form" :: I.classIf opts.inline "n-form--inline")) ]
        ++ (case opts.onSubmit of
                Just msg ->
                    [ HE.onSubmit msg ]

                Nothing ->
                    []
           )


{-| Embed one caller `Element` inside the raw `<form>`. elm-ui has no public
`Element` → `Html` conversion, so a layout root is the only bridge; the wrapper
is neutralised with `display: contents` + inherited font/colour (see the module
docs).

`noStaticStyleSheet`: without it elm-ui re-emits its static stylesheet as a
`<style>` node inside every embed. Those nodes land **after** the bridge
(`NUI.Css`, which restores `flex-basis`/`line-height`/`white-space` at equal
specificity) in document order and re-declare `.s.r > .s { flex-basis: 0% }`,
re-clobbering `flex-basis: auto` page-wide. The app's own `Element.layout`
supplies the sheet once. elm-ui still emits a small _dynamic_ (font) sheet per
embed; it carries no `flex-basis`, so it is harmless.
`NUI.Descriptions.embedChild` carries the same fix.

-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child


{-| One `n-form-item`: the label, the blank (the caller's children) and the
feedback wrapper, in that order. The root always carries the size and
placement classes; `--no-label` only when `showLabel` resolves to `False`.
-}
item : Theme -> ItemOptions -> List (Element msg) -> Element msg
item theme opts children =
    Element.column
        [ I.classes (itemClasses opts), I.cssVars (cssVarsForItem theme opts) ]
        (List.filterMap identity
            [ labelMaybe opts
            , Just (blankElement opts children)
            , feedbackMaybe opts
            ]
        )


itemClasses : ItemOptions -> List String
itemClasses opts =
    List.concat
        [ [ "n-form-item"
          , "n-form-item--" ++ sizeClass opts.size ++ "-size"
          , "n-form-item--" ++ placementClass (placementOf opts) ++ "-labelled"
          ]
        , I.classIf (not (showLabelResolved opts)) "n-form-item--no-label"
        ]


sizeClass : Size -> String
sizeClass size =
    case size of
        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"


placementClass : Placement -> String
placementClass placement =
    case placement of
        Top ->
            "top"

        Left ->
            "left"


placementOf : ItemOptions -> Placement
placementOf opts =
    Maybe.withDefault Top opts.labelPlacement


showLabelResolved : ItemOptions -> Bool
showLabelResolved opts =
    Maybe.withDefault True opts.showLabel


{-| The label, or `Nothing` when it is hidden or there is no text (upstream's
`renderLabel` returns `null` for an empty label, so an unlabelled item renders
no label element — and, when `showLabel` is not `False`, no `--no-label`
either).
-}
labelMaybe : ItemOptions -> Maybe (Element msg)
labelMaybe opts =
    if not (showLabelResolved opts) then
        Nothing

    else
        case opts.label of
            Just text ->
                if String.isEmpty text then
                    Nothing

                else
                    Just (labelElement opts text)

            Nothing ->
                Nothing


labelElement : ItemOptions -> String -> Element msg
labelElement opts text =
    Element.html
        (Html.label
            (labelAttrs opts)
            (labelChildren opts text)
        )


labelAttrs : ItemOptions -> List (Html.Attribute msg)
labelAttrs opts =
    [ HA.class (String.join " " (labelClasses opts)) ]
        ++ (case opts.labelFor of
                Just f ->
                    [ HA.for f ]

                Nothing ->
                    []
           )
        ++ (case mergedLabelStyle opts of
                Just style ->
                    [ HA.attribute "style" style ]

                Nothing ->
                    []
           )


labelClasses : ItemOptions -> List String
labelClasses opts =
    List.concat
        [ [ "n-form-item-label"
          , "n-form-item-label--" ++ markPlacementClass opts.requireMarkPlacement ++ "-mark"
          ]
        , I.classIf (reverseColumnsSpace opts) "n-form-item-label--reverse-columns-space"
        ]


markPlacementClass : RequireMarkPlacement -> String
markPlacementClass placement =
    case placement of
        MarkLeft ->
            "left"

        MarkRight ->
            "right"

        MarkRightHanging ->
            "right-hanging"


{-| Upstream's `reverseColSpace`: left placement + a left mark + a prop-level
`AlignLeft` label align. (The align is the raw prop, not the theme-resolved
value.)
-}
reverseColumnsSpace : ItemOptions -> Bool
reverseColumnsSpace opts =
    placementOf opts
        == Left
        && opts.requireMarkPlacement
        == MarkLeft
        && opts.labelAlign
        == Just AlignLeft


labelChildren : ItemOptions -> String -> List (Html.Html msg)
labelChildren opts text =
    let
        textNode =
            Html.span [ HA.class "n-form-item-label__text" ] [ Html.text text ]

        markNodes =
            if showRequireMark opts then
                [ Html.span
                    [ HA.class "n-form-item-label__asterisk" ]
                    [ Html.text
                        (if opts.requireMarkPlacement == MarkLeft then
                            "*\u{00A0}"

                         else
                            "\u{00A0}*"
                        )
                    ]
                ]

            else if opts.requireMarkPlacement == MarkRightHanging then
                [ Html.span
                    [ HA.class "n-form-item-label__asterisk-placeholder" ]
                    [ Html.text "\u{00A0}*" ]
                ]

            else
                []
    in
    if opts.requireMarkPlacement == MarkLeft then
        markNodes ++ [ textNode ]

    else
        textNode :: markNodes


{-| `showRequireMark ?? required` — `Nothing` shows the mark iff the item is
required.
-}
showRequireMark : ItemOptions -> Bool
showRequireMark opts =
    Maybe.withDefault opts.required opts.showRequireMark


{-| The label's inline style: `labelStyle` first, then the label width (which
wins). Width is emitted only under `Left` placement; `Px n` becomes `"npx"`,
`Custom` is verbatim.
-}
mergedLabelStyle : ItemOptions -> Maybe String
mergedLabelStyle opts =
    let
        width =
            case opts.labelWidth of
                Just (Px n) ->
                    if placementOf opts == Left then
                        Just ("width:" ++ String.fromInt n ++ "px")

                    else
                        Nothing

                Just (Custom custom) ->
                    if placementOf opts == Left then
                        Just ("width:" ++ custom)

                    else
                        Nothing

                Nothing ->
                    Nothing

        parts =
            List.filterMap identity [ opts.labelStyle, width ]
    in
    if List.isEmpty parts then
        Nothing

    else
        Just (String.join ";" parts)


{-| The blank: the status modifier (bare `error` / `warning` word),
`contentClass` / `contentStyle`, and the caller's children.
-}
blankElement : ItemOptions -> List (Element msg) -> Element msg
blankElement opts children =
    Element.column
        (I.classes (blankClasses opts) :: blankStyleAttrs opts)
        children


blankClasses : ItemOptions -> List String
blankClasses opts =
    List.concat
        [ [ "n-form-item-blank" ]
        , extraClass opts.contentClass
        , statusModifier "n-form-item-blank" (itemStatus opts)
        ]


blankStyleAttrs : ItemOptions -> List (Element.Attribute msg)
blankStyleAttrs opts =
    case opts.contentStyle of
        Just style ->
            if String.isEmpty style then
                []

            else
                [ Element.htmlAttribute (HA.attribute "style" style) ]

        Nothing ->
            []


{-| The feedback wrapper — rendered whenever `showFeedback`, even with no lines
(upstream renders it unconditionally; the `:not(:empty)` rule exists for that).
`feedbackClass` / `feedbackStyle` land on the wrapper.
-}
feedbackMaybe : ItemOptions -> Maybe (Element msg)
feedbackMaybe opts =
    if opts.showFeedback then
        Just (feedbackElement opts)

    else
        Nothing


feedbackElement : ItemOptions -> Element msg
feedbackElement opts =
    Element.html
        (Html.div
            (feedbackWrapperAttrs opts)
            (feedbackInner opts)
        )


feedbackWrapperAttrs : ItemOptions -> List (Html.Attribute msg)
feedbackWrapperAttrs opts =
    [ HA.class (String.join " " ("n-form-item-feedback-wrapper" :: extraClass opts.feedbackClass)) ]
        ++ (case opts.feedbackStyle of
                Just style ->
                    if String.isEmpty style then
                        []

                    else
                        [ HA.attribute "style" style ]

                Nothing ->
                    []
           )


{-| The inner status div and its lines. Lines are the controlled `feedback`
when set, else the validation messages in order; with no lines the wrapper is
empty (no inner div).
-}
feedbackInner : ItemOptions -> List (Html.Html msg)
feedbackInner opts =
    let
        lines =
            case opts.feedback of
                Just line ->
                    [ line ]

                Nothing ->
                    List.map .message (Maybe.withDefault [] opts.validation)
    in
    if List.isEmpty lines then
        []

    else
        [ Html.div
            [ HA.class (String.join " " (statusClasses (itemStatus opts))) ]
            (List.map
                (\line ->
                    Html.div [ HA.class "n-form-item-feedback__line" ] [ Html.text line ]
                )
                lines
            )
        ]


statusClasses : Maybe Level -> List String
statusClasses status =
    "n-form-item-feedback" :: statusModifier "n-form-item-feedback" status


{-| The bare status word appended to a class (upstream `--${status}`, no
`-status` suffix).
-}
statusModifier : String -> Maybe Level -> List String
statusModifier base status =
    case status of
        Just ErrorLevel ->
            [ base ++ "--error" ]

        Just WarningLevel ->
            [ base ++ "--warning" ]

        Nothing ->
            []


{-| The item's merged validation status: an explicit `validationStatus` wins,
else the highest level present in `validation`.
-}
itemStatus : ItemOptions -> Maybe Level
itemStatus opts =
    case opts.validationStatus of
        Just level ->
            Just level

        Nothing ->
            let
                feedback =
                    Maybe.withDefault [] opts.validation
            in
            if List.any (\fb -> fb.level == ErrorLevel) feedback then
                Just ErrorLevel

            else if List.any (\fb -> fb.level == WarningLevel) feedback then
                Just WarningLevel

            else
                Nothing


extraClass : Maybe String -> List String
extraClass maybeClass =
    case maybeClass of
        Just c ->
            if String.isEmpty c then
                []

            else
                [ c ]

        Nothing ->
            []


{-| The 16 `--n-*` custom properties the item root attaches (upstream
FormItem.tsx:485-502) — per-size / per-placement selection and the
label-text-align resolution.
-}
cssVarsForItem : Theme -> ItemOptions -> List ( String, String )
cssVarsForItem theme opts =
    let
        v =
            FormTheme.vars theme

        placement =
            placementOf opts
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-blank-height", blankHeight v opts.size )
    , ( "--n-label-font-size", labelFontSize v placement opts.size )
    , ( "--n-label-text-align", labelTextAlign v opts )
    , ( "--n-label-height", labelHeight v opts.size )
    , ( "--n-label-padding", labelPadding v placement )
    , ( "--n-label-font-weight", v.labelFontWeight )
    , ( "--n-asterisk-color", v.asteriskColor )
    , ( "--n-label-text-color", v.labelTextColor )
    , ( "--n-feedback-padding", v.feedbackPadding )
    , ( "--n-feedback-font-size", feedbackFontSize v opts.size )
    , ( "--n-feedback-height", feedbackHeight v opts.size )
    , ( "--n-feedback-text-color", v.feedbackTextColor )
    , ( "--n-feedback-text-color-warning", v.feedbackTextColorWarning )
    , ( "--n-feedback-text-color-error", v.feedbackTextColorError )
    ]


blankHeight : FormTheme.Vars -> Size -> String
blankHeight v size =
    case size of
        Small ->
            v.blankHeightSmall

        Medium ->
            v.blankHeightMedium

        Large ->
            v.blankHeightLarge


labelHeight : FormTheme.Vars -> Size -> String
labelHeight v size =
    case size of
        Small ->
            v.labelHeightSmall

        Medium ->
            v.labelHeightMedium

        Large ->
            v.labelHeightLarge


labelFontSize : FormTheme.Vars -> Placement -> Size -> String
labelFontSize v placement size =
    case ( placement, size ) of
        ( Top, Small ) ->
            v.labelFontSizeTopSmall

        ( Top, Medium ) ->
            v.labelFontSizeTopMedium

        ( Top, Large ) ->
            v.labelFontSizeTopLarge

        ( Left, Small ) ->
            v.labelFontSizeLeftSmall

        ( Left, Medium ) ->
            v.labelFontSizeLeftMedium

        ( Left, Large ) ->
            v.labelFontSizeLeftLarge


feedbackFontSize : FormTheme.Vars -> Size -> String
feedbackFontSize v size =
    case size of
        Small ->
            v.feedbackFontSizeSmall

        Medium ->
            v.feedbackFontSizeMedium

        Large ->
            v.feedbackFontSizeLarge


feedbackHeight : FormTheme.Vars -> Size -> String
feedbackHeight v size =
    case size of
        Small ->
            v.feedbackHeightSmall

        Medium ->
            v.feedbackHeightMedium

        Large ->
            v.feedbackHeightLarge


labelPadding : FormTheme.Vars -> Placement -> String
labelPadding v placement =
    case placement of
        Top ->
            v.labelPaddingVertical

        Left ->
            v.labelPaddingHorizontal


{-| The resolved label align. `labelAlign` wins over the theme value (vertical
for `Top`, horizontal for `Left`); under `Top`, `right` maps to `flex-end` and
anything else to `flex-start` (upstream FormItem.tsx:480-484).
-}
labelTextAlign : FormTheme.Vars -> ItemOptions -> String
labelTextAlign v opts =
    let
        themeAlign =
            case placementOf opts of
                Top ->
                    v.labelTextAlignVertical

                Left ->
                    v.labelTextAlignHorizontal

        align =
            case opts.labelAlign of
                Just AlignLeft ->
                    "left"

                Just AlignCenter ->
                    "center"

                Just AlignRight ->
                    "right"

                Nothing ->
                    themeAlign
    in
    case placementOf opts of
        Top ->
            if align == "right" then
                "flex-end"

            else
                "flex-start"

        Left ->
            align
