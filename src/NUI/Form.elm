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

{-| Naive UI's `Form` + `FormItem` — STUB (API contract pinned; bodies land in
the GREEN step). See the module TODO: engine/view split per
`NUI.Countdown` / `NUI.LoadingBar`.
-}

import Element exposing (Element)
import NUI.Theme exposing (Theme)


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


{-| Validate one field's rules — STUB.
-}
validateValue : Maybe Trigger -> String -> List Rule -> Maybe Value -> List Feedback
validateValue _ _ _ _ =
    []


{-| Validate every (filtered) rule path — STUB.
-}
validateForm : Maybe Trigger -> Maybe (List String) -> Rules -> Values -> List ( String, List Feedback )
validateForm _ _ _ _ =
    []


{-| Upstream's `mergedRequired` (rules side) — STUB.
-}
isRequired : List Rule -> Bool
isRequired _ =
    False


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


{-| The `form.n-form` wrapper — STUB.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none


{-| One `n-form-item` — STUB.
-}
item : Theme -> ItemOptions -> List (Element msg) -> Element msg
item _ _ _ =
    Element.none


{-| The 16 `--n-*` vars the item root attaches — STUB.
-}
cssVarsForItem : Theme -> ItemOptions -> List ( String, String )
cssVarsForItem _ _ =
    []
