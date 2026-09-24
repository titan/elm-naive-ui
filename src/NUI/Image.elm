module NUI.Image exposing
    ( ObjectFit(..)
    , Options
    , cssVars
    , defaults
    , errorReplacesImg
    , loadingValue
    , resolveSrc
    , view
    )

{-| Naive UI's `Image`, rebuilt on elm-ui.

    import NUI.Image exposing (defaults)

    NUI.Image.view theme NUI.Image.defaults

    NUI.Image.view theme
        { defaults
        | src = Just "https://example.com/pic.jpeg"
        , width = Just "200"
        , objectFit = NUI.Image.Contain
        }

The visual result is Naive UI's own: the element carries the `.n-image` BEM
classes and `NUI.Css` ships Naive UI's exact CSS.

The state machine is caller-owned (Split/Rate/Slider precedent): the port
exposes the render surface and the pure branches of upstream's `showError` /
`loaded` / `shouldStartLoading` logic, and the caller drives those flags
through their own `Msg` from the `onError` / `onLoad` seams plus their
intersection-observer or native-lazy runtime.

Preview seam (batch 1): upstream wraps the img in `NImagePreview`, whose
modal surface is teleported to the body. The port keeps the flow content
byte-equivalent (`n-image` root > img) and hands the caller the preview's
`cssVars` (upstream emits the five `--n-*` vars on the preview container,
not the `n-image` root) plus the click seam to open their preview runtime.

Accepted edges (documented divergences, kept for batch-1 scope):

  - No `NImagePreview` child and no `NImageGroup` context yet. Upstream's
    flow DOM for a non-group image is the same `img` under the root; the
    modal (toolbar / overlay / drag / keyboard) is the preview batch.
  - The img always carries `data-group-id=""` — upstream sets it on mount
    even outside a group (`Image.tsx` `onMounted`).
  - `loading` assumes native lazy support (`isImageSupportNativeLazy`,
    true in every browser this port targets).
  - Upstream's `loadDescription` prop is declared but never consumed —
    not ported.

Note: record updates bind `defaults` to a local first, then patch fields.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as Events
import Json.Decode as Decode
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Image as ImageTheme


type ObjectFit
    = Fill
    | Contain
    | Cover
    | None
    | ScaleDown


type alias Options msg =
    { src : Maybe String
    , alt : Maybe String
    , width : Maybe String
    , height : Maybe String
    , objectFit : ObjectFit
    , lazy : Bool
    , intersectionObserver : Bool
    , shouldStartLoading : Bool
    , loaded : Bool
    , showError : Bool
    , fallbackSrc : Maybe String
    , previewSrc : Maybe String
    , previewDisabled : Bool
    , error : Maybe (Element msg)
    , placeholder : Maybe (Element msg)
    , imgAttributes : List (Html.Attribute msg)
    , onClick : Maybe msg
    , onError : Maybe msg
    , onLoad : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { src = Nothing
    , alt = Nothing
    , width = Nothing
    , height = Nothing
    , objectFit = Fill
    , lazy = False
    , intersectionObserver = False
    , shouldStartLoading = True
    , loaded = False
    , showError = False
    , fallbackSrc = Nothing
    , previewSrc = Nothing
    , previewDisabled = False
    , error = Nothing
    , placeholder = Nothing
    , imgAttributes = []
    , onClick = Nothing
    , onError = Nothing
    , onLoad = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> Element msg
view _ opts =
    let
        imgEl =
            if errorReplacesImg opts then
                opts.error
                    |> Maybe.map List.singleton
                    |> Maybe.withDefault []

            else
                [ Element.html (Html.img (imgAttributes opts) []) ]

        placeholderEl =
            if opts.loaded then
                []

            else
                opts.placeholder
                    |> Maybe.map List.singleton
                    |> Maybe.withDefault []
    in
    Element.row
        (I.classes (rootClasses opts)
            :: Element.htmlAttribute (HA.attribute "role" "none")
            :: opts.attributes
        )
        (imgEl ++ placeholderEl)


{-| Upstream's class array: `[$attrs.class, "n-image",
(previewDisabled || showError) && "n-image--preview-disabled"]`.
-}
rootClasses : Options msg -> List String
rootClasses opts =
    List.concat
        [ [ "n-image" ]
        , I.classIf (opts.previewDisabled || opts.showError) "n-image--preview-disabled"
        ]


{-| The img attribute list, in upstream emission order: the `imgProps`
spread first (caller `imgAttributes`), then width, height, src, alt +
aria-label, the three event seams, `loading`, the style pack, `data-error`,
`data-preview-src`, and the post-mount `data-group-id=""`.
-}
imgAttributes : Options msg -> List (Html.Attribute msg)
imgAttributes opts =
    let
        alt =
            opts.alt

        previewSrc =
            case opts.previewSrc of
                Just p ->
                    Just p

                Nothing ->
                    opts.src
    in
    List.concat
        [ opts.imgAttributes
        , List.filterMap identity
            [ Maybe.map (HA.attribute "width") opts.width
            , Maybe.map (HA.attribute "height") opts.height
            , Maybe.map HA.src (resolveSrc opts)
            , Maybe.map (\a -> HA.attribute "alt" a) alt
            , Maybe.map (\a -> HA.attribute "aria-label" a) alt
            ]
        , case opts.onClick of
            Just msg ->
                [ Events.onClick msg ]

            Nothing ->
                []
        , case opts.onError of
            Just msg ->
                [ Events.on "error" (Decode.succeed msg) ]

            Nothing ->
                []
        , case opts.onLoad of
            Just msg ->
                [ Events.on "load" (Decode.succeed msg) ]

            Nothing ->
                []
        , [ HA.attribute "loading" (loadingValue opts) ]
        , styleAttributes opts
        , [ HA.attribute "data-error"
                (if opts.showError then
                    "true"

                 else
                    "false"
                )
          ]
        , case previewSrc of
            Just p ->
                [ HA.attribute "data-preview-src" p ]

            Nothing ->
                []
        , [ HA.attribute "data-group-id" "" ]
        ]


{-| Upstream's style array: `[imgProps.style || '', placeholderNode && !
loaded ? { height: '0', width: '0', visibility: 'hidden' } : '',
{ objectFit }]` — the hide pack sits before the object-fit entry.
-}
styleAttributes : Options msg -> List (Html.Attribute msg)
styleAttributes opts =
    (if opts.placeholder /= Nothing && not opts.loaded then
        [ HA.style "height" "0"
        , HA.style "width" "0"
        , HA.style "visibility" "hidden"
        ]

     else
        []
    )
        ++ [ HA.style "object-fit" (objectFitToString opts.objectFit) ]


{-| Upstream's src ternary (Image.tsx render):

    showError            -> fallbackSrc
    lazy && observerOpts -> (shouldStartLoading ? loadSrc : undefined)
    otherwise            -> loadSrc

where `loadSrc = src` (upstream also folds `imgProps.src` in; set `src`).
`Nothing` means the attribute is omitted.

-}
resolveSrc : Options msg -> Maybe String
resolveSrc opts =
    if opts.showError then
        opts.fallbackSrc

    else if opts.lazy && opts.intersectionObserver then
        if opts.shouldStartLoading then
            opts.src

        else
            Nothing

    else
        opts.src


{-| The error slot replaces the whole img node when shown
(`showError && errorNode.length`).
-}
errorReplacesImg : Options msg -> Bool
errorReplacesImg opts =
    opts.showError && opts.error /= Nothing


{-| `isImageSupportNativeLazy && lazy && !intersectionObserverOptions
? 'lazy' : 'eager'`, with the env flag hardwired to true (native lazy
support is universal in targeted browsers).
-}
loadingValue : Options msg -> String
loadingValue opts =
    if opts.lazy && not opts.intersectionObserver then
        "lazy"

    else
        "eager"


objectFitToString : ObjectFit -> String
objectFitToString fit =
    case fit of
        Fill ->
            "fill"

        Contain ->
            "contain"

        Cover ->
            "cover"

        None ->
            "none"

        ScaleDown ->
            "scale-down"


{-| The five `--n-*` vars upstream emits on the image-preview **container**
(ImagePreview.tsx `cssVarsRef`), in emission order. The `n-image` root
itself carries no inline vars — apply these to the caller's preview
surface until the preview batch lands.
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        v =
            ImageTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-toolbar-icon-color", v.toolbarIconColor )
    , ( "--n-toolbar-color", v.toolbarColor )
    , ( "--n-toolbar-border-radius", v.toolbarBorderRadius )
    , ( "--n-toolbar-box-shadow", v.toolbarBoxShadow )
    ]
