module NUI.DynamicTags exposing (Options, cssVarsFor, defaults, view)

{-| Naive UI's `DynamicTags`, rebuilt on elm-ui.

    import NUI.DynamicTags exposing (defaults)

    NUI.DynamicTags.view theme
        { defaults
            | value = [ "hello", "world" ]
            , onUpdateValue = Just SetTags
            , onActivate = Just ShowInput
            , onConfirm = Just ConfirmTag
            , onInputValue = Just SetDraft
        }
        []

The root is an `NUI.Space` (`size small`) carrying the `n-dynamic-tags` class
and the `--n-input-width` variable; one `NUI.Tag` renders per entry, followed by
the add trigger (a dashed `NUI.Button` with Naive UI's add icon) or the input.
The peers (Space / Tag / Input / Button) are rendered with the theme you pass
in — upstream injects `theme.peers.*`, which a pure port has no equivalent of.
The stylesheet's own rule `.n-dynamic-tags .n-input { min-width:
var(--n-input-width) }` constrains whichever input renders inside the root:
the built-in one or the custom input slot.

**Runtime (caller-owned).** Upstream keeps three refs — the tag list, whether
the input is showing, and the input's draft text. This library is pure, so all
three live in your model and the view reports through messages:

  - `onActivate` — the add trigger was clicked (upstream `handleAddClick`);
    set `showInput = True`.

  - `onInputValue` — the built-in input's text changed; store it in
    `inputValue`.

  - `onConfirm` — the built-in input was confirmed (Enter key or blur —
    upstream `handleInputConfirm`); append the draft, hide the input and clear
    it:
    update Confirm model =
    { model
    | tags =
    if model.draft == "" then
    model.tags

                  else
                      model.tags ++ [ model.draft ]
              , showInput = False
              , draft = ""
          }

  - `onUpdateValue` — a tag's close button was clicked (upstream
    `handleCloseClick`), receiving the full next list (the closed tag removed).

The trailing `view` argument is upstream's `input` slot: non-empty, its
elements render in place of the built-in input when `showInput = True` — you
own their events. Likewise `trigger` replaces the add button; wire its click to
whatever sets `showInput = True`. The built-in input is wrapped in a plain
element carrying the Enter / blur confirm listeners (the input component takes
no event attributes of its own).

**Not modelled** (upstream props with no pure-view counterpart): `renderTag`,
`onCreate` (the string port needs no label transform), `DynamicTagsOption`
objects (tags are plain strings), the `tagClass` / `tagStyle` / `inputClass` /
`inputStyle` / `inputProps` passthroughs, form-item disabled merging, the IME
`isCompositing` guard on Enter, `internalForceFocus`, and NSpace's
`itemStyle="display: flex;"` (our Space renders children directly, so there are
no item wrappers to style).

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import NUI.Button as Button
import NUI.Input as Input
import NUI.Internal as I
import NUI.Space as Space
import NUI.Tag as Tag
import NUI.Theme exposing (Theme)
import NUI.Theme.DynamicTags as DynamicTagsTheme
import NUI.Types as T exposing (Kind(..), Size(..))


type alias Options msg =
    { value : List String
    , size : Size
    , kind : Kind
    , round : Bool
    , color : Maybe String
    , closable : Bool
    , disabled : Bool
    , max : Maybe Int
    , showInput : Bool
    , inputValue : String
    , trigger : Maybe (Element msg)
    , onUpdateValue : Maybe (List String -> msg)
    , onInputValue : Maybe (String -> msg)
    , onActivate : Maybe msg
    , onConfirm : Maybe msg
    }


defaults : Options msg
defaults =
    { value = []
    , size = Medium
    , kind = Default
    , round = False
    , color = Nothing
    , closable = True
    , disabled = False
    , max = Nothing
    , showInput = False
    , inputValue = ""
    , trigger = Nothing
    , onUpdateValue = Nothing
    , onInputValue = Nothing
    , onActivate = Nothing
    , onConfirm = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts inputSlot =
    let
        spaceBase =
            Space.defaults
    in
    Space.view theme
        { spaceBase
            | size = Space.Small

            -- n-dynamic-tags + the --n-* custom properties join the Space's
            -- own inline styles (classes attach first, so both style sources
            -- survive on the same node).
            , attributes =
                [ I.classes [ "n-dynamic-tags" ]
                , I.cssVars (cssVarsFor theme)
                ]
        }
        (List.indexedMap (tagEl theme opts) opts.value
            ++ (if opts.showInput then
                    if List.isEmpty inputSlot then
                        [ inputEl theme opts ]

                    else
                        inputSlot

                else
                    [ triggerEl theme opts ]
               )
        )


{-| The root's `--n-*` custom properties — upstream's `cssVarsRef` emits only
`--n-input-width`.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    [ ( "--n-input-width", DynamicTagsTheme.vars theme |> .inputWidth ) ]



-- children -------------------------------------------------------------------


{-| One `NTag` per entry: the tag props (`type` / `round` / `size` / `color` /
`closable` / `disabled`) forward as-is, `onClose` reports the list without this
tag (upstream `handleCloseClick`).
-}
tagEl : Theme -> Options msg -> Int -> String -> Element msg
tagEl theme opts index label =
    let
        base =
            Tag.defaults
    in
    Tag.view theme
        { base
            | kind = opts.kind
            , size = opts.size
            , round = opts.round
            , color = opts.color
            , closable = opts.closable
            , disabled = opts.disabled
            , onClose =
                Maybe.map (\toMsg -> toMsg (removeAt index opts.value)) opts.onUpdateValue
        }
        [ Element.text label ]


{-| The built-in `NInput`: empty placeholder, `smallerSize` of the component
size, its text and typing events caller-owned. The wrapper carries the
Enter / blur confirm events (upstream `onKeydown` Enter + `onBlur`).
-}
inputEl : Theme -> Options msg -> Element msg
inputEl theme opts =
    let
        base =
            Input.defaults
    in
    Element.el (confirmAttrs opts)
        (Input.view theme
            { base
                | value = opts.inputValue
                , onInput = opts.onInputValue
                , placeholder = Just ""
                , size = smallerSize opts.size
            }
        )


confirmAttrs : Options msg -> List (Element.Attribute msg)
confirmAttrs opts =
    case opts.onConfirm of
        Just msg ->
            [ onEnter msg, onFocusOut msg ]

        Nothing ->
            []


{-| The default trigger: a dashed `NButton` at the input size, disabled with
the component (`disabled` or `max` reached), showing Naive UI's `AddIcon`.
-}
triggerEl : Theme -> Options msg -> Element msg
triggerEl theme opts =
    case opts.trigger of
        Just custom ->
            custom

        Nothing ->
            let
                base =
                    Button.defaults
            in
            Button.view theme
                { base
                    | dashed = True
                    , disabled = triggerDisabled opts
                    , size = smallerSize opts.size
                    , onPress = opts.onActivate
                    , icon = Just addIcon
                }
                []


{-| Upstream `triggerDisabledRef`: `mergedDisabled || (!!max && value.length >= max)`.
-}
triggerDisabled : Options msg -> Bool
triggerDisabled opts =
    opts.disabled
        || (case opts.max of
                Just max ->
                    List.length opts.value >= max

                Nothing ->
                    False
           )



-- helpers --------------------------------------------------------------------


{-| Upstream's `smallerSize`: the add input and trigger button render one size
below the tags. (`tiny` maps to upstream's `mini`, which our `Size` enum has no
member for — and upstream's own DynamicTags prop only accepts small / medium /
large — so it stays `tiny`.)
-}
smallerSize : Size -> Size
smallerSize size =
    case size of
        Tiny ->
            Tiny

        Small ->
            Tiny

        Medium ->
            Small

        Large ->
            Medium


{-| Upstream `handleCloseClick`: `tags.splice(index, 1)`.
-}
removeAt : Int -> List String -> List String
removeAt index tags =
    List.append (List.take index tags) (List.drop (index + 1) tags)


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (HE.on "keydown"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "not Enter"
                    )
            )
        )


{-| Blur does not bubble; `focusout` is its bubbling counterpart and covers
focus leaving the whole input.
-}
onFocusOut : msg -> Element.Attribute msg
onFocusOut msg =
    Element.htmlAttribute (HE.on "focusout" (Decode.succeed msg))



-- ICON (Naive UI renders this through NBaseIcon: an `<i class="n-base-icon">`)


addIcon : Element msg
addIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ addSvg ])


addSvg : Html.Html msg
addSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 512 512"
        , HA.attribute "fill" "none"
        ]
        [ Html.node "path"
            [ HA.attribute "d" "M256 112V400M400 256H112"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-width" "32"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            ]
            []
        ]
