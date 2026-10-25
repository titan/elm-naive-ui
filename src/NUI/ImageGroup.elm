module NUI.ImageGroup exposing
    ( Options, currentId, currentUrl, defaults, go, imageIds
    , nextIndex, prevIndex, previewOptions, showImage, urlMap, view
    )

{-| Naive UI's `ImageGroup`, rebuilt on elm-ui.

@docs Options, currentId, currentUrl, defaults, go, imageIds
@docs nextIndex, prevIndex, previewOptions, showImage, urlMap, view

    import NUI.ImageGroup as ImageGroup

    ImageGroup.view theme
        { ImageGroup.defaults
            | srcList = [ url1, url2, url3 ]
            , current = 0
            , show = True
            , onPrev = Just PrevMsg
            , onNext = Just NextMsg
            , onClose = Just Closed
        }

Upstream `NImageGroup` renders its children (the `n-image`s) as
`NImagePreview`'s slot and mounts the preview container via LazyTeleport.
The port keeps both halves explicit (no teleport, `NUI.Modal` precedent):
you render the `n-image` children in flow yourself, and `view` renders the
preview container — `ImageGroup.view` emits exactly the
`NUI.ImagePreview` tree fed from the group state, so mount it under the
same rules (unmount when fully closed, keep mounted through leave phases).

Note: record updates bind `defaults` to a local first, then patch fields.

Essential contract: `view` emits exactly the `NUI.ImagePreview` tree fed
from the group state — mount it under the same rules (unmount when fully
closed, keep mounted through leave phases) and render the `n-image`
children in flow yourself. Two url registries (`srcList`'s `p${index}`
keys WIN over `registered`'s `r`-scheme pairs — don't mix), the wrap-around
index walk and the two prev/next paths (toolbar = reset + `go`, keyboard =
`go` only) are specified below.

DOM shapes, fidelity notes and porting details live in the comment block
below the module doc.

-}

{- DOM shapes, fidelity notes and porting details for `NUI.ImageGroup` — moved verbatim
      out of the module docstring (docs.json must stay under elm publish's 768kb
      limit); plain comments do not enter the published API docs.

   Two url registries, byte-faithful to upstream's merged map:

     - `srcList` — the `p${index}` keys (`p0`, `p1`, …). When non-empty it
       WINS over the registered map, and upstream throws if a child `n-image`
       registers anyway (a caller-side contract here — don't mix them).
     - `registered` — the `r`-scheme entries the child `n-image`s contribute,
       as `(imageId, url)` pairs. Model it as upstream's keyed map: keep the
       imageIds UNIQUE and let a later registration overwrite (upstream's
       `registerImageUrl` double-prefixes its `has('r' + sid)` check, so the
       `set` always runs — re-registration overwrites the url); and treat
       unregistration as a no-op (upstream's `unregisterPreviewUrl` deletes
       only when the key is NOT present, so it never deletes — unmounted
       children stay walkable in the wrap space). The port does not dedupe
       for you; duplicate ids would double-count in `imageIds` and skew the
       walk's index space.

   Index walk (all pure, upstream bytes):

     - `nextIndex` / `prevIndex` wrap around, skipping falsy urls
       (empty strings) — `Just index` only when some url exists.
     - `go 1` / `go -1` is upstream's `go(step)`: step 1 moves to `nextIndex`
       (and is what upstream's toolbar "next" fires, `onPreviewNext` along the
       way), step -1 to `prevIndex`.
     - `showImage imageId` is `toggleShow`'s `setCurrentId` half: index of the
       id, set only when it differs. `toggleShow` also opens (`show = True`) —
       do both in your msg handler.
     - `currentId` / `currentUrl` read the merged registry.

   Prev/next wiring (upstream has TWO paths with different resets): the
   toolbar switch buttons route through `handleSwitchPrev/Next` — reset the
   zoom (`NUI.ImagePreview.switchReset`), then fire `go`. The document
   keyboard handlers (←/→) fire the RAW prev/next — `go` WITHOUT the reset.
   So the `onPrev` / `onNext` msgs here are YOUR toolbar msgs (reset + go);
   keep the keyboard path reset-free by mapping `NUI.ImagePreview.keyAction`
   Prev/Next to `go` only.

   `NUI.ImagePreview`'s `previewedImgProps` do not apply: in group mode
   upstream's preview gets no `imageContext` (the inject fails), so the img
   carries no controlled class/style — the port omits those fields entirely.

   Accepted edges:

     - Child `n-image`s don't auto-register (no injection in a pure tree) —
       you thread their urls into `registered` yourself; their thumbnails keep
       `data-group-id=""` (upstream stamps a random `c<uuid>` there, which is
       not byte-pinnable).
     - `groupId`, `renderToolbar`, `showToolbarTooltip`, `keepDragOffset` ride
       the preview's seams/edges (see `NUI.ImagePreview`).
-}

import Element exposing (Element)
import NUI.ImagePreview as Preview
import NUI.Internal as I
import NUI.Theme exposing (Theme)



-- OPTIONS


{-| The `n-image-group` props — the group's url registries, the walk state,
and the preview-surface flags threaded straight into `NUI.ImagePreview`
(`zoom` IS the preview's `Zoom`, the three `*Transition` phases hold its
nodes mounted through leave fades, `wrapperStyle` feeds `syncTransformOrigin`).
The `onPrev` / `onNext` msgs are the toolbar switch msgs (reset + `go`);
the keyboard path fires `go` only (see the module docs).
-}
type alias Options msg =
    { srcList : List String
    , registered : List ( String, String )
    , current : Int
    , show : Bool
    , showToolbar : Bool
    , zoom : Preview.Zoom
    , dragging : Bool
    , imgDerived : Bool
    , imgTransition : Bool
    , overlayTransition : Maybe I.TransitionPhase
    , toolbarTransition : Maybe I.TransitionPhase
    , wrapperTransition : Maybe I.TransitionPhase
    , wrapperStyle : List ( String, String )
    , onPrev : Maybe msg
    , onNext : Maybe msg
    , onClose : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


{-| A closed, hidden group: empty registries, `current = 0`, toolbar on, the
preview's initial zoom and all leave phases clear.
-}
defaults : Options msg
defaults =
    { srcList = []
    , registered = []
    , current = 0
    , show = False
    , showToolbar = True
    , zoom = Preview.zoom0
    , dragging = False
    , imgDerived = False
    , imgTransition = True
    , overlayTransition = Nothing
    , toolbarTransition = Nothing
    , wrapperTransition = Nothing
    , wrapperStyle = []
    , onPrev = Nothing
    , onNext = Nothing
    , onClose = Nothing
    , attributes = []
    }



-- REGISTRY (the merged url map, pure)


{-| The merged registry, `srcList` winning over `registered` exactly as
upstream's `mergedImageUrlMap`. Keys follow upstream's scheme: `p${index}`
for the list, the caller's image ids for the registered entries.
-}
urlMap : Options msg -> List ( String, String )
urlMap opts =
    if opts.srcList /= [] then
        List.indexedMap (\i url -> ( "p" ++ String.fromInt i, url )) opts.srcList

    else
        opts.registered


{-| The registry's key list, in order — the index space `current` walks.
-}
imageIds : Options msg -> List String
imageIds =
    urlMap >> List.map Tuple.first


{-| `currentId` — the key at `current`, `Nothing` when out of range.
-}
currentId : Options msg -> Maybe String
currentId opts =
    List.drop opts.current (imageIds opts)
        |> List.head


{-| `currentUrl` — upstream's `src` for the preview. Falsy (empty) urls are
returned as `Just ""` here; the walk in `nextIndex`/`prevIndex` skips them.
-}
currentUrl : Options msg -> Maybe String
currentUrl opts =
    currentId opts
        |> Maybe.andThen
            (\id ->
                urlMap opts
                    |> List.filter (\( k, _ ) -> k == id)
                    |> List.head
                    |> Maybe.map Tuple.second
            )



-- INDEX WALK


{-| `nextIndex`: scan `current + 1 .. count - 1` for the first entry with a
truthy (non-empty) url, then wrap `0 .. current - 1`.
-}
nextIndex : Options msg -> Maybe Int
nextIndex opts =
    let
        count =
            List.length (imageIds opts)

        find range =
            range
                |> List.filter
                    (\i ->
                        urlAt i opts
                            |> Maybe.map (\u -> u /= "")
                            |> Maybe.withDefault False
                    )
                |> List.head
    in
    case find (List.range (opts.current + 1) (count - 1)) of
        Just i ->
            Just i

        Nothing ->
            find (List.range 0 (opts.current - 1))


{-| `prevIndex`: the mirror scan (`current - 1 .. 0`, then wrap from the
tail).
-}
prevIndex : Options msg -> Maybe Int
prevIndex opts =
    let
        count =
            List.length (imageIds opts)

        find range =
            range
                |> List.filter
                    (\i ->
                        urlAt i opts
                            |> Maybe.map (\u -> u /= "")
                            |> Maybe.withDefault False
                    )
                |> List.head
    in
    case find (List.range 0 (opts.current - 1) |> List.reverse) of
        Just i ->
            Just i

        Nothing ->
            find (List.range (opts.current + 1) (count - 1) |> List.reverse)


urlAt : Int -> Options msg -> Maybe String
urlAt i opts =
    urlMap opts
        |> List.drop i
        |> List.head
        |> Maybe.map Tuple.second


{-| `go(step)`: step 1 → `nextIndex`, step -1 → `prevIndex`; `current`
unchanged when the walk finds nothing. Upstream also fires
`onPreviewNext`/`onPreviewPrev` — fold that into the msg that calls `go`.
-}
go : Int -> Options msg -> Options msg
go step opts =
    let
        target =
            if step == 1 then
                nextIndex opts

            else
                prevIndex opts
    in
    case target of
        Just i ->
            { opts | current = i }

        Nothing ->
            opts


{-| `setCurrentId` (the `toggleShow` half): index of `imageId`, written only
when it differs from `current`. Unknown ids leave the state untouched
(upstream's `indexOf` → -1 → differs → would set -1; here out-of-range ids
are refused — a `-1` current is unreachable through the public API).
-}
showImage : String -> Options msg -> Options msg
showImage imageId opts =
    case indexOf imageId (imageIds opts) of
        Just i ->
            if i /= opts.current then
                { opts | current = i }

            else
                opts

        Nothing ->
            opts


indexOf : String -> List String -> Maybe Int
indexOf target list =
    case list of
        [] ->
            Nothing

        first :: rest ->
            if first == target then
                Just 0

            else
                Maybe.map ((+) 1) (indexOf target rest)



-- VIEW


{-| The preview tree fed from the group state — the exact
`NUI.ImagePreview.view` this renders is upstream's group-mounted preview.
Mount it next to your `n-image` children (upstream renders the children as
its slot, then the container).
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Preview.view theme (previewOptions opts)


{-| The `NUI.ImagePreview.Options` the group state maps onto — exposed for
pins and for callers that need to style the container through the preview's
richer fields.
-}
previewOptions : Options msg -> Preview.Options msg
previewOptions opts =
    { show = opts.show
    , src = currentUrl opts
    , showToolbar = opts.showToolbar
    , zoom = opts.zoom
    , dragging = opts.dragging
    , imgDerived = opts.imgDerived
    , imgTransition = opts.imgTransition
    , overlayTransition = opts.overlayTransition
    , toolbarTransition = opts.toolbarTransition
    , wrapperTransition = opts.wrapperTransition
    , wrapperStyle = opts.wrapperStyle
    , onPrev = opts.onPrev
    , onNext = opts.onNext
    , onClose = opts.onClose
    , onRotateCounterclockwise = Nothing
    , onRotateClockwise = Nothing
    , onOriginalSize = Nothing
    , onZoomOut = Nothing
    , onZoomIn = Nothing
    , onDownload = Nothing
    , onImgMousedown = Nothing
    , onImgDblclick = Nothing
    , onImgDragstart = Nothing
    , previewedImgClass = Nothing
    , previewedImgStyle = []
    , previewedImgAttributes = []
    , attributes = opts.attributes
    }
