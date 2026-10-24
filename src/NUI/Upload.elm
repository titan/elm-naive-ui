module NUI.Upload exposing (FileInfo, ListType(..), Options, Status(..), appendFile, buttonKindOf, cssVarsFor, defaults, filesToSubmit, isImageFile, markError, markFinished, markRemoved, markUploading, matchType, maxReached, pendingFile, progressStatusOf, removeFileById, settle, shouldUseThumbnailUrlDefault, sliceForMax, updateFileList, view, viewAbstract, viewDragger, viewFileList, viewTrigger)

{-| Naive UI's `Upload`, rebuilt on elm-ui.

    import NUI.Upload as Upload
    import NUI.Theme as Theme

    Upload.view Theme.default
        { Upload.defaults
            | fileList =
                [ { id = "a"
                  , batchId = Nothing
                  , name = "a.png"
                  , percentage = Just 42
                  , status = Upload.Uploading
                  , url = Nothing
                  , thumbnailUrl = Nothing
                  , type_ = Nothing
                  , fullPath = Nothing
                  }
                ]
        }

The DOM is Naive UI's own: the root `div.n-upload` (the 16 `--n-*` vars), the
`input.n-upload-file-input`, the `div.n-upload-trigger` (with its image-card
dragger), the `div.n-upload-file-list` and the `div.n-upload-file` rows
(`__info` / `__thumbnail` / `__name` / `__action`), plus the line progress bar
while a file is uploading. `css/naive-ui.css` ships Naive UI's exact CSS.

**Caller-owned runtime.** Upstream's `Upload` is an imperative component: it
opens the file dialog, drives XHR (or a `customRequest`), reads `File` objects
into a `FileList`, resolves thumbnails asynchronously and serialises
`doChange` through `nextTick`. This library is pure, so the port exposes the
render surface and the **pure state machine**, and the host app owns the
effects:

  - `fileList` is the caller's list. Every open/close/append/replace is a
    caller update; the module's `settle` / `pendingFile` / `updateFileList` /
    `appendFile` / `removeFileById` / `mark*` helpers are the ports of
    upstream's `createSettledFileInfo` / `handleFileAddition` / `doChange` /
    the XHR-handler transitions — the caller applies them in its `Msg` handlers.
  - The events (`onTriggerClick` / `onFileChange` / `onDrop` /
    `onDragStateChange` / `onRemove` / `onRetry` / `onDownload` / `onPreview`)
    are Elm channels — Vue listeners never become DOM attributes (no byte
    impact). `onFileChange` fires on the input's `change`; read the picked
    `File`s through ports, run `handleFileAddition`'s pure steps
    (`sliceForMax` + `pendingFile` + `appendFile`), then submit.

**Accepted edges (documented divergences):**

1.  `file : File` is dropped from `FileInfo` — Elm has no `File`. Thumbnail
    resolution (`createImageDataUrl` / `URL.createObjectURL`) is caller-side:
    write the resolved URL into `thumbnailUrl`. `environmentSupportFile ≡
    true` (every targeted browser supports it).
2.  XHR + `customRequest` + `onBeforeUpload` / `onFinish` / `onError` rewrites
      - directory-entry (`webkitGetAsEntry`) traversal are host ports; the
        module exposes only the pure transitions (`markUploading` /
        `markFinished` / `markError` / `markRemoved`, `filesToSubmit`).
3.  `draggerInside` is explicit (a pure tree cannot introspect the slot for
    `uploadDraggerKey`); `abstract` renders a Fragment — upstream teleports
    the input to `body`, the port returns `[ inputNode, slot ]` for the caller
    to place.
4.  `onRemove` carries the file **id** (upstream passes `{ file, fileList,
    index }` — the caller derives those); the trigger's `options`-object slot
    is dropped (wire drag/click messages directly).
5.  RTL is dropped (`rtlEnabled` defaults false, house precedent).
6.  `scheduleDoChange` / `nextTick` serialisation is unnecessary in a
    synchronous pure render.
7.  `defaultUpload` auto-submit after addition is the caller's
    responsibility — `filesToSubmit` is the selection rule, nothing
    auto-fires.
8.  The `value = ''` reset of the `<input>` after a change is a host DOM
    command (Elm holds no element ref).
9.  The image-card thumbnail's `NImage` is embedded through `Element.layoutWith`
    (`display:contents` wrapper) — elm-ui has no public `Element → Html`. The
    `NImage`-in-`NImageGroup` context is the same approximation `NUI.Image`
    documents (no group registration, `data-group-id=""`).
10. `imageGroupOptions` is accepted for API parity but is inert: upstream's
    `NImageGroup` renders a Fragment (its preview container is teleported to
    `body`), so it adds no in-flow node to the file list — mount
    `NUI.ImageGroup.view` yourself with the file urls.

Fidelity notes: the `n-upload-file--info-status` / `--success-status` classes
are emitted upstream with no cssr rule (only `--error-status` has one), as is
`n-upload-file-info__action--text-type`; the icon glyphs are byte-verbatim
(9 private constants). The action buttons are icon-only `NUI.Button`s carrying
`varOverrides = { paddingMedium, heightMedium, iconSizeMedium }`
(`UploadFile.tsx:21-25`); they always render an empty `n-button__content`
(the `NUI.Button` content-span behaviour, shared with `NUI.InputNumber`).
[oracle D13] The root and (abstract) file-list class arrays omit Naive UI's
inline-theme `themeClass` (house-wide: the inline-theme-optimisation class
never lands in this port; no-op under the default theme).

\`never lands in this port; no-op under the default theme).

Upstream refs: `upload/src/Upload.tsx` (render :655-680, cssVars :507-561,
`doChange` :331-366, `handleFileAddition` :367-433, `submit` :434-480),
`UploadTrigger.tsx`, `UploadFileList.tsx`, `UploadFile.tsx`,
`UploadDragger.tsx`, `UploadProgress.tsx`, `utils.ts`, `icons.tsx`.

@docs FileInfo, ListType, Options, Status, appendFile, buttonKindOf, cssVarsFor, defaults, filesToSubmit, isImageFile, markError, markFinished, markRemoved, markUploading, matchType, maxReached, pendingFile, progressStatusOf, removeFileById, settle, shouldUseThumbnailUrlDefault, sliceForMax, updateFileList, view, viewAbstract, viewDragger, viewFileList, viewTrigger

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import NUI.Button as Button
import NUI.Image as Image
import NUI.ImageGroup as ImageGroup
import NUI.Internal as I
import NUI.Progress as Progress
import NUI.Theme exposing (Theme)
import NUI.Theme.Upload as UploadTheme
import NUI.Types as T
import Regex
import Svg



-- TYPES -------------------------------------------------------------------------


{-| Upstream's `file.status`: `['pending', 'uploading', 'finished', 'removed',
'error']`.
-}
type Status
    = Pending
    | Uploading
    | Finished
    | Removed
    | Error


{-| Upstream's `listType` prop.
-}
type ListType
    = Text
    | Image
    | ImageCard


{-| Upstream's `UploadSettledFileInfo` minus the `file : File` field (Elm has
no `File` — see the module notes). Every optional field is already `Maybe`
(upstream's `?? null` normalisation).
-}
type alias FileInfo =
    { id : String
    , batchId : Maybe String
    , name : String
    , percentage : Maybe Int
    , status : Status
    , url : Maybe String
    , thumbnailUrl : Maybe String
    , type_ : Maybe String
    , fullPath : Maybe String
    }


{-| The upload options: the `fileList` state plus the display switches
(`listType`, the five action-button flags, `abstract`), the trigger / file
input wiring (`accept`, `multiple`, `directory`, the handlers), and the
render-override slots. The drag state (`dragOver`, `draggerInside`) is
caller-owned data driven by `onDragStateChange`.
-}
type alias Options msg =
    { fileList : List FileInfo
    , showFileList : Bool
    , listType : ListType
    , showTrigger : Bool
    , accept : Maybe String
    , multiple : Bool
    , directory : Bool
    , directoryDnd : Maybe Bool
    , disabled : Bool
    , max : Maybe Int
    , dragOver : Bool
    , draggerInside : Bool
    , abstract : Bool
    , alwaysShowActions : Bool
    , showCancelButton : Bool
    , showRemoveButton : Bool
    , showDownloadButton : Bool
    , showRetryButton : Bool
    , showPreviewButton : Bool
    , triggerClass : Maybe String
    , triggerStyle : Maybe String
    , fileListClass : Maybe String
    , fileListStyle : Maybe String
    , inputAttributes : List (Html.Attribute msg)
    , triggerNode : Maybe (Element msg)
    , imageGroupOptions : Maybe (ImageGroup.Options msg)
    , renderIcon : Maybe (FileInfo -> Element msg)
    , shouldUseThumbnailUrl : Maybe (FileInfo -> Bool)
    , onTriggerClick : Maybe msg
    , onFileChange : Maybe msg
    , onDrop : Maybe msg
    , onDragStateChange : Maybe (Bool -> msg)
    , onRemove : Maybe (String -> msg)
    , onRetry : Maybe (String -> msg)
    , onDownload : Maybe (String -> msg)
    , onPreview : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: text list shown, trigger shown, no max, no abstract
wrap, all five action buttons available per status, no handlers.
-}
defaults : Options msg
defaults =
    { fileList = []
    , showFileList = True
    , listType = Text
    , showTrigger = True
    , accept = Nothing
    , multiple = False
    , directory = False
    , directoryDnd = Nothing
    , disabled = False
    , max = Nothing
    , dragOver = False
    , draggerInside = False
    , abstract = False
    , alwaysShowActions = False
    , showCancelButton = True
    , showRemoveButton = True
    , showDownloadButton = False
    , showRetryButton = True
    , showPreviewButton = True
    , triggerClass = Nothing
    , triggerStyle = Nothing
    , fileListClass = Nothing
    , fileListStyle = Nothing
    , inputAttributes = []
    , triggerNode = Nothing
    , imageGroupOptions = Nothing
    , renderIcon = Nothing
    , shouldUseThumbnailUrl = Nothing
    , onTriggerClick = Nothing
    , onFileChange = Nothing
    , onDrop = Nothing
    , onDragStateChange = Nothing
    , onRemove = Nothing
    , onRetry = Nothing
    , onDownload = Nothing
    , onPreview = Nothing
    , attributes = []
    }



-- PURE MIRRORS ------------------------------------------------------------------


{-| Upstream `createSettledFileInfo`: normalises every optional field with
`?? null`. In Elm the optionals are already `Maybe`, so this is the identity on
a `FileInfo` — kept as a named port for the state machine.
-}
settle : FileInfo -> FileInfo
settle raw =
    { id = raw.id
    , batchId = raw.batchId
    , name = raw.name
    , percentage = raw.percentage
    , status = raw.status
    , url = raw.url
    , thumbnailUrl = raw.thumbnailUrl
    , type_ = raw.type_
    , fullPath = raw.fullPath
    }


{-| Upstream's `handleFileAddition` per-file stamp: `percentage: 0`,
`status: 'pending'`, `url` / `thumbnailUrl` `null`.
-}
pendingFile : { id : String, name : String, type_ : Maybe String, fullPath : Maybe String, batchId : Maybe String } -> FileInfo
pendingFile raw =
    { id = raw.id
    , batchId = raw.batchId
    , name = raw.name
    , percentage = Just 0
    , status = Pending
    , url = Nothing
    , thumbnailUrl = Nothing
    , type_ = raw.type_
    , fullPath = raw.fullPath
    }


{-| Upstream `doChange`'s replace-by-id branch: splice the changed file into
its position; an id-miss is a no-op (upstream's dev warning).
-}
updateFileList : FileInfo -> List FileInfo -> List FileInfo
updateFileList file list =
    case indexOfId file.id list of
        Just i ->
            List.take i list ++ (file :: List.drop (i + 1) list)

        Nothing ->
            list


{-| Upstream `doChange`'s append branch: push to the end.
-}
appendFile : FileInfo -> List FileInfo -> List FileInfo
appendFile file list =
    list ++ [ file ]


{-| Upstream `doChange`'s remove branch: splice at the id's index; an id-miss
is a no-op.
-}
removeFileById : String -> List FileInfo -> List FileInfo
removeFileById id list =
    case indexOfId id list of
        Just i ->
            List.take i list ++ List.drop (i + 1) list

        Nothing ->
            list


indexOfId : String -> List FileInfo -> Maybe Int
indexOfId id list =
    list
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, f ) -> f.id == id)
        |> List.head
        |> Maybe.map Tuple.first


{-| Upstream's progress-handler transition: `status: 'uploading'`,
`percentage` set. The percentage LATCH lives with the caller (upstream keeps
it in a closure).
-}
markUploading : Int -> FileInfo -> FileInfo
markUploading percentage file =
    { file | status = Uploading, percentage = Just percentage }


{-| Upstream's load-handler transition — **status only**: the last latched
`percentage` survives (`Object.assign({}, file, { status: 'finished' })`).
-}
markFinished : FileInfo -> FileInfo
markFinished file =
    { file | status = Finished }


{-| Upstream's error-handler transition — **status only** (the latched
percentage survives).
-}
markError : FileInfo -> FileInfo
markError file =
    { file | status = Error }


{-| Upstream's abort-handler transition: `status: 'removed'` (the `file: null`
half is not modelled — `FileInfo` carries no `File`).
-}
markRemoved : FileInfo -> FileInfo
markRemoved file =
    { file | status = Removed }


{-| Upstream `submit`'s target rule: with a `fileId`, only that file; without,
the whole list. A file uploads when `status === 'pending'`, or when
`status === 'error'` and the submit is a retry (or was targeted by id).
-}
filesToSubmit : { fileId : Maybe String, retry : Bool } -> List FileInfo -> List FileInfo
filesToSubmit query list =
    let
        targets =
            case query.fileId of
                Just id ->
                    List.filter (\f -> f.id == id) list

                Nothing ->
                    list

        shouldReupload =
            query.retry || query.fileId /= Nothing
    in
    List.filter
        (\f -> f.status == Pending || (f.status == Error && shouldReupload))
        targets


{-| Upstream `maxReachedRef`: `max !== undefined && fileList.length >= max`.
-}
maxReached : Options msg -> Bool
maxReached opts =
    case opts.max of
        Just m ->
            List.length opts.fileList >= m

        Nothing ->
            False


{-| Upstream's `max` slice in `handleFileAddition`: keep the first
`max - currentLen` incoming files. No `max` keeps every incoming file.

Accepted edge (oracle R1): when `max - currentLen` is negative, JS
`arr.slice(0, negative)` counts from the END (a from-end prefix) while this
port returns `[]` (List.take semantics) — unreachable inside the component,
because `handleFileAddition` only runs while `!maxReached`, so the cap is
always ≥ 1 there.

(Design surface named this `sliceForMax`; the port returns the sliced list —
the operation upstream actually performs — rather than the bare count, so the
`Nothing` case has a meaningful value.)

-}
sliceForMax : Maybe Int -> Int -> List a -> List a
sliceForMax max currentLen list =
    case max of
        Just m ->
            List.take (Basics.max 0 (m - currentLen)) list

        Nothing ->
            list


{-| Upstream `matchType` (`utils.ts:145`), byte-faithful:

    name =
        name.toLowerCase ()

    mimeType =
        mimeType.toLocaleLowerCase ()

    accept =
        accept.toLocaleLowerCase ()

`toLocaleLowerCase` and `toLowerCase` coincide for ASCII, and Elm's
`String.toLower` is an ASCII fold — the accept/mime lowercasing is modelled
with it. An atom starting with `.` is a suffix match on the name; an atom
containing `/` is a mime match with `*` wildcards on either side; any other
atom (no dot, no slash — an "invalid type") matches everything.

-}
matchType : String -> String -> String -> Bool
matchType name mimeType accept =
    let
        lowerName =
            String.toLower name

        lowerMime =
            String.toLower mimeType

        atoms =
            accept
                |> String.toLower
                |> String.split ","
                |> List.map String.trim
                |> List.filter (\s -> s /= "")
    in
    List.any (matchAtom lowerName lowerMime) atoms


matchAtom : String -> String -> String -> Bool
matchAtom name mimeType atom =
    if String.startsWith "." atom then
        String.endsWith atom name

    else if String.contains "/" atom then
        let
            ( type_, subtype ) =
                splitParts mimeType

            ( acceptType, acceptSubtype ) =
                splitParts atom
        in
        (acceptType == "*" || (type_ /= "" && acceptType == type_))
            && (acceptSubtype == "*" || (subtype /= "" && acceptSubtype == subtype))

    else
        True


{-| JS `s.split('/')`'s first two elements (a missing second element is the
empty string, matching upstream's `undefined` truthiness check).
-}
splitParts : String -> ( String, String )
splitParts s =
    case String.split "/" s of
        first :: second :: _ ->
            ( first, second )

        [ first ] ->
            ( first, "" )

        [] ->
            ( "", "" )


{-| Upstream `isImageFile` (`utils.ts:24`), byte-faithful — `type` short-circuits
when truthy, else the name extension, else `thumbnailUrl || url` (a
`data:image/` prefix or a matching extension). `getExtname` is private (pinned
through this function).
-}
isImageFile : FileInfo -> Bool
isImageFile file =
    case file.type_ of
        Just t ->
            if t /= "" then
                isImageFileType t

            else
                imageByExtensionOrUrl file

        Nothing ->
            imageByExtensionOrUrl file


isImageFileType : String -> Bool
isImageFileType t =
    String.contains "image/" t


imageByExtensionOrUrl : FileInfo -> Bool
imageByExtensionOrUrl file =
    if Regex.contains imageExtensionRegex (getExtname file.name) then
        True

    else
        let
            url =
                jsOr file.thumbnailUrl file.url
        in
        String.startsWith "data:image/" url
            || Regex.contains imageExtensionRegex (getExtname url)


{-| Upstream's `isImageFile` default `shouldUseThumbnailUrl` (browser:
`environmentSupportFile && isImageFile` → `isImageFile`).
-}
shouldUseThumbnailUrlDefault : FileInfo -> Bool
shouldUseThumbnailUrlDefault =
    isImageFile


{-| `progressStatus` (`UploadFile.tsx:59`): finished → success, error → error,
everything else → info.
-}
progressStatusOf : Status -> Progress.Status
progressStatusOf status =
    case status of
        Finished ->
            Progress.Success

        Error ->
            Progress.Error

        _ ->
            Progress.Info


{-| `buttonType` (`UploadFile.tsx:69`): error-status rows get error-kind
buttons; every other status leaves the button type at its default.
-}
buttonKindOf : Status -> Maybe T.Kind
buttonKindOf status =
    case status of
        Error ->
            Just T.Error

        _ ->
            Nothing



-- EXTENSION / URL HELPERS -------------------------------------------------------


{-| `utils.ts`'s `imageExtensionRegex` — `(webp|svg|png|gif|jpg|jpeg|jfif|bmp|dpg|ico)$/i`.
-}
imageExtensionRegex : Regex.Regex
imageExtensionRegex =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } "(webp|svg|png|gif|jpg|jpeg|jfif|bmp|dpg|ico)$"
        |> Maybe.withDefault Regex.never


{-| `utils.ts`'s `getExtname`: the last `/` segment, cut at the first `#`/`?`,
then the `/\.[^./\\]*$/` match (the extension, else the empty string).
-}
getExtname : String -> String
getExtname url =
    let
        filename =
            url
                |> String.split "/"
                |> List.reverse
                |> List.head
                |> Maybe.withDefault ""

        withoutSuffix =
            cutAtSuffix filename
    in
    case Regex.find extnameRegex withoutSuffix of
        match :: _ ->
            match.match

        [] ->
            ""


extnameRegex : Regex.Regex
extnameRegex =
    Regex.fromString "\\.[^./\\\\]*$" |> Maybe.withDefault Regex.never


{-| `filename.split(/#|\?/)[0]` — the part before the first `#` or `?`.
-}
cutAtSuffix : String -> String
cutAtSuffix s =
    case Regex.find suffixRegex s of
        match :: _ ->
            String.left match.index s

        [] ->
            s


suffixRegex : Regex.Regex
suffixRegex =
    Regex.fromString "#|\\?" |> Maybe.withDefault Regex.never


{-| JS `a || b || ''` for two optionals (an empty string is falsy).
-}
jsOr : Maybe String -> Maybe String -> String
jsOr a b =
    case a of
        Just s ->
            if s == "" then
                Maybe.withDefault "" b

            else
                s

        Nothing ->
            Maybe.withDefault "" b


{-| `mergedThumbnailUrl` (`UploadFile.tsx:97`) minus the async resolver: the
first truthy of `thumbnailUrl`, `url`.
-}
mergedThumbnailUrl : FileInfo -> Maybe String
mergedThumbnailUrl file =
    firstTruthy [ file.thumbnailUrl, file.url ]


firstTruthy : List (Maybe String) -> Maybe String
firstTruthy =
    List.foldr
        (\maybeValue acc ->
            case maybeValue of
                Just s ->
                    if s == "" then
                        acc

                    else
                        Just s

                Nothing ->
                    acc
        )
        Nothing


useThumbnailUrl : Options msg -> FileInfo -> Bool
useThumbnailUrl opts file =
    case opts.shouldUseThumbnailUrl of
        Just f ->
            f file

        Nothing ->
            isImageFile file



-- VIEW -------------------------------------------------------------------------


{-| The non-abstract root: `div.n-upload` (16 vars) > input, trigger (unless
image-card), file list.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.column
        (I.classes (rootClasses opts) :: I.cssVars (cssVarsFor theme) :: opts.attributes)
        (inputNode opts
            :: ((if opts.showTrigger && opts.listType /= ImageCard then
                    [ viewTrigger theme opts ]

                 else
                    []
                )
                    ++ (if opts.showFileList then
                            [ viewFileList theme opts ]

                        else
                            []
                       )
               )
        )


rootClasses : Options msg -> List String
rootClasses opts =
    List.concat
        [ [ "n-upload" ]
        , I.classIf opts.draggerInside "n-upload--dragger-inside"
        , I.classIf opts.dragOver "n-upload--drag-over"
        ]


{-| The abstract output — a Fragment: the input node plus the caller's slot
content (upstream teleports the input to `body`; place these where the input
belongs).
-}
viewAbstract : Theme -> Options msg -> Element msg -> List (Element msg)
viewAbstract _ opts slot =
    [ inputNode opts, slot ]


{-| The file `<input>` (always the root's first child), raw-embedded so it is a
direct node. `inputAttributes` spread FIRST, then `type` / `class` / `accept` /
`multiple` / `webkitdirectory` / `directory`.
-}
inputNode : Options msg -> Element msg
inputNode opts =
    Element.html <|
        Html.node "input"
            (opts.inputAttributes
                ++ [ HA.type_ "file"
                   , HA.class "n-upload-file-input"
                   ]
                ++ (case opts.accept of
                        Just a ->
                            [ HA.attribute "accept" a ]

                        Nothing ->
                            []
                   )
                ++ (if opts.multiple || opts.directory then
                        [ HA.multiple True ]

                    else
                        []
                   )
                ++ (if opts.directory then
                        [ HA.attribute "webkitdirectory" ""
                        , HA.attribute "directory" ""
                        ]

                    else
                        []
                   )
                ++ (case opts.onFileChange of
                        Just msg ->
                            [ HE.on "change" (Decode.succeed msg) ]

                        Nothing ->
                            []
                   )
            )
            []


{-| The trigger `div.n-upload-trigger` (in image-card mode it wraps a dragger
whose default content is Naive UI's `AddIcon`).
-}
viewTrigger : Theme -> Options msg -> Element msg
viewTrigger _ opts =
    let
        disabled =
            opts.disabled || maxReached opts

        classes =
            List.concat
                [ [ "n-upload-trigger" ]
                , I.classIf disabled "n-upload-trigger--disabled"
                , I.classIf (opts.listType == ImageCard) "n-upload-trigger--image-card"
                , case opts.triggerClass of
                    Just c ->
                        [ c ]

                    Nothing ->
                        []
                ]

        styleAttrs =
            case opts.triggerStyle of
                Just s ->
                    [ Element.htmlAttribute (HA.attribute "style" s) ]

                Nothing ->
                    []

        eventAttrs =
            (case opts.onTriggerClick of
                Just msg ->
                    [ Events.onClick msg ]

                Nothing ->
                    []
            )
                ++ (case opts.onDrop of
                        Just msg ->
                            [ Element.htmlAttribute (HE.on "drop" (Decode.succeed msg)) ]

                        Nothing ->
                            []
                   )
                ++ (case opts.onDragStateChange of
                        Just toMsg ->
                            [ Element.htmlAttribute (HE.on "dragover" (Decode.succeed (toMsg True)))
                            , Element.htmlAttribute (HE.on "dragenter" (Decode.succeed (toMsg True)))
                            , Element.htmlAttribute (HE.on "dragleave" (Decode.succeed (toMsg False)))
                            ]

                        Nothing ->
                            []
                   )
    in
    Element.column (I.classes classes :: styleAttrs ++ eventAttrs) (triggerChildren opts)


triggerChildren : Options msg -> List (Element msg)
triggerChildren opts =
    if opts.listType == ImageCard then
        [ viewDragger opts
            [ Maybe.withDefault (baseIconElement addIconSvg) opts.triggerNode ]
        ]

    else
        case opts.triggerNode of
            Just node ->
                [ node ]

            Nothing ->
                []


{-| The dragger `div.n-upload-dragger` (`--disabled` while disabled or maxed).
-}
viewDragger : Options msg -> List (Element msg) -> Element msg
viewDragger opts children =
    Element.column
        [ I.classes
            ([ "n-upload-dragger" ]
                ++ I.classIf (opts.disabled || maxReached opts) "n-upload-dragger--disabled"
            )
        ]
        children


{-| The file-list `div.n-upload-file-list` (`--grid` in image-card mode). In
abstract mode it carries the theme vars itself; `fileListStyle` is merged after.
-}
viewFileList : Theme -> Options msg -> Element msg
viewFileList theme opts =
    let
        isImageCard =
            opts.listType == ImageCard

        classes =
            List.concat
                [ [ "n-upload-file-list" ]
                , I.classIf isImageCard "n-upload-file-list--grid"
                , case opts.fileListClass of
                    Just c ->
                        [ c ]

                    Nothing ->
                        []
                ]
    in
    Element.column
        (fillWidth :: I.classes classes :: fileListStyleAttrs theme opts)
        (List.indexedMap (fileRow theme opts) opts.fileList
            ++ (if opts.showTrigger && not (maxReached opts) && isImageCard then
                    [ viewTrigger theme opts ]

                else
                    []
               )
        )


fileListStyleAttrs : Theme -> Options msg -> List (Element.Attribute msg)
fileListStyleAttrs theme opts =
    let
        parts =
            List.filter (\s -> s /= "")
                [ if opts.abstract then
                    I.renderVars (cssVarsFor theme)

                  else
                    ""
                , Maybe.withDefault "" opts.fileListStyle
                ]
    in
    if List.isEmpty parts then
        []

    else
        [ Element.htmlAttribute (HA.attribute "style" (String.join ";" parts)) ]



-- FILE ROW ----------------------------------------------------------------------


fileRow : Theme -> Options msg -> Int -> FileInfo -> Element msg
fileRow theme opts _ file =
    let
        status =
            progressStatusOf file.status

        isImageType =
            opts.listType == Image

        progressList =
            if file.status == Uploading then
                [ progressNode theme file ]

            else
                []

        nameDiv =
            Element.column
                [ I.classes [ "n-upload-file-info__name" ] ]
                (nameContent opts file
                    ++ (if isImageType then
                            progressList

                        else
                            []
                       )
                )

        infoDiv =
            Element.row
                [ I.classes [ "n-upload-file-info" ], fillWidth ]
                [ thumbnailNode theme opts file, nameDiv, actionNode theme opts file ]
    in
    Element.column
        [ I.classes (fileRowClasses opts file status), fillWidth ]
        (infoDiv
            :: (if isImageType then
                    []

                else
                    progressList
               )
        )


fileRowClasses : Options msg -> FileInfo -> Progress.Status -> List String
fileRowClasses opts file status =
    List.concat
        [ [ "n-upload-file"
          , statusClass status
          ]
        , I.classIf
            (fileUrlTruthy file && file.status /= Error && opts.listType /= ImageCard)
            "n-upload-file--with-url"
        , [ listTypeSuffix opts.listType |> (\s -> "n-upload-file--" ++ s ++ "-type")
          ]
        , I.classIf opts.alwaysShowActions "n-upload-file--always-show-actions"
        ]


{-| JS truthiness of `file.url` (`UploadFile.tsx:326/:339`): `null` AND the
empty string are both falsy — `url = Just ""` suppresses `--with-url` and
keeps the name a `span` (oracle S2).
-}
fileUrlTruthy : FileInfo -> Bool
fileUrlTruthy file =
    case file.url of
        Just u ->
            u /= ""

        Nothing ->
            False


statusClass : Progress.Status -> String
statusClass status =
    case status of
        Progress.Success ->
            "n-upload-file--success-status"

        Progress.Error ->
            "n-upload-file--error-status"

        _ ->
            "n-upload-file--info-status"


listTypeSuffix : ListType -> String
listTypeSuffix listType =
    case listType of
        Text ->
            "text"

        Image ->
            "image"

        ImageCard ->
            "image-card"


showName : ListType -> Bool
showName listType =
    listType == Text || listType == Image


nameContent : Options msg -> FileInfo -> List (Element msg)
nameContent opts file =
    if showName opts.listType then
        [ Element.html (nameHtml opts file) ]

    else
        []


nameHtml : Options msg -> FileInfo -> Html.Html msg
nameHtml opts file =
    let
        onClickAttrs =
            case opts.onPreview of
                Just toMsg ->
                    [ HE.onClick (toMsg file.id) ]

                Nothing ->
                    []

        textNode =
            Html.text file.name
    in
    if fileUrlTruthy file && file.status /= Error then
        Html.a
            ([ HA.attribute "rel" "noopener noreferer"
             , HA.attribute "target" "_blank"
             ]
                ++ (case file.url of
                        Just u ->
                            [ HA.href u ]

                        Nothing ->
                            []
                   )
                ++ onClickAttrs
            )
            [ textNode ]

    else
        Html.span onClickAttrs [ textNode ]


{-| The `__thumbnail` slot. Text rows show the attach icon (or `renderIcon`);
image / image-card rows show the thumbnail anchor when there is a usable url,
else the image / document icon.
-}
thumbnailNode : Theme -> Options msg -> FileInfo -> Element msg
thumbnailNode theme opts file =
    Element.html (thumbnailHtml theme opts file)


thumbnailHtml : Theme -> Options msg -> FileInfo -> Html.Html msg
thumbnailHtml theme opts file =
    let
        isImageCard =
            opts.listType == ImageCard

        isImage =
            isImageCard || opts.listType == Image

        thumbUrl =
            mergedThumbnailUrl file
    in
    if isImage && useThumbnailUrl opts file && thumbUrl /= Nothing then
        Html.a (thumbnailAnchorAttrs opts file)
            [ thumbnailAnchorChild theme isImageCard thumbUrl file ]

    else if isImage then
        Html.span [ HA.class "n-upload-file-info__thumbnail" ]
            [ thumbnailIcon opts file True ]

    else
        Html.span [ HA.class "n-upload-file-info__thumbnail" ]
            [ thumbnailIcon opts file False ]


thumbnailAnchorAttrs : Options msg -> FileInfo -> List (Html.Attribute msg)
thumbnailAnchorAttrs opts file =
    [ HA.attribute "rel" "noopener noreferer"
    , HA.attribute "target" "_blank"
    ]
        ++ (case file.url of
                Just u ->
                    [ HA.href u ]

                Nothing ->
                    []
           )
        ++ [ HA.class "n-upload-file-info__thumbnail" ]
        ++ (case opts.onPreview of
                Just toMsg ->
                    [ HE.onClick (toMsg file.id) ]

                Nothing ->
                    []
           )


thumbnailAnchorChild : Theme -> Bool -> Maybe String -> FileInfo -> Html.Html msg
thumbnailAnchorChild theme isImageCard thumbUrl file =
    if isImageCard then
        embedEl
            (Image.view theme
                (let
                    imageDefaults =
                        Image.defaults
                 in
                 { imageDefaults
                    | src = thumbUrl
                    , previewSrc = file.url
                    , alt = Just file.name
                 }
                )
            )

    else
        Html.img
            ((case thumbUrl of
                Just u ->
                    [ HA.src u ]

                Nothing ->
                    []
             )
                ++ [ HA.attribute "alt" file.name ]
            )
            []


thumbnailIcon : Options msg -> FileInfo -> Bool -> Html.Html msg
thumbnailIcon opts file isImageType =
    case opts.renderIcon of
        Just render ->
            embedEl (render file)

        Nothing ->
            if isImageType then
                Html.i [ HA.class "n-base-icon" ]
                    [ if isImageFile file then
                        imageIconSvg

                      else
                        documentIconSvg
                    ]

            else
                Html.i [ HA.class "n-base-icon" ] [ attachSvg ]



-- ACTION BUTTONS ----------------------------------------------------------------


{-| elm-ui's `.s.c > .s.wc` (width-content child of a column) sets
`align-self: flex-start`, so the file-list, each file row and the
`__info` row collapse to their content width. Upstream renders all of them
as plain full-width block divs (`n-upload-file { display: block }`), so the
`__action` strip's `position: absolute; right: 0; width: 80px` lands at the
row's right edge and `__name`'s `flex: 1` + `overflow: hidden` ellipsis
reserve those 80px — collapsed rows instead center the shrunken name
underneath the button strip (they overlap). `Element.width Element.fill`
restores the browser default (`.wf → width: 100%` under the column chain,
`.s.r > .s.wf → flex-grow` inside the info row). Same seam as `Menu` /
`List` / `Dropdown` / `PageHeader`'s `fillWidth`. The image-card row is
unaffected: its `width: 96px` comes from a higher-specificity Naive rule.
-}
fillWidth : Element.Attribute msg
fillWidth =
    Element.width Element.fill


actionNode : Theme -> Options msg -> FileInfo -> Element msg
actionNode theme opts file =
    let
        kind =
            Maybe.withDefault T.Default (buttonKindOf file.status)

        showCancel =
            opts.showCancelButton && List.member file.status [ Uploading, Pending, Error ]

        showRemove =
            opts.showRemoveButton && file.status == Finished

        showRetry =
            opts.showRetryButton && file.status == Error

        showDownload =
            opts.showDownloadButton && file.status == Finished

        showPreview =
            opts.showPreviewButton
                && file.status
                == Finished
                && mergedThumbnailUrl file
                /= Nothing
                && opts.listType
                == ImageCard

        previewButton =
            if showPreview then
                [ uploadButton theme kind (baseIconElement eyeIconSvg) (previewMsg opts file) ]

            else
                []

        cancelButton =
            if (showRemove || showCancel) && not opts.disabled then
                [ uploadButton theme
                    kind
                    (baseIconElement
                        (if showRemove then
                            trashIconSvg

                         else
                            cancelIconSvg
                        )
                    )
                    (onRemoveMsg opts file)
                ]

            else
                []

        retryButton =
            if showRetry && not opts.disabled then
                [ uploadButton theme kind (baseIconElement retryIconSvg) (onRetryMsg opts file) ]

            else
                []

        downloadButton =
            if showDownload then
                [ uploadButton theme kind (baseIconElement downloadIconSvg) (onDownloadMsg opts file) ]

            else
                []

        classes =
            List.concat
                [ [ "n-upload-file-info__action"
                  , "n-upload-file-info__action--" ++ listTypeSuffix opts.listType ++ "-type"
                  ]
                , I.classIf opts.alwaysShowActions "n-upload-file-info__action--always-show"
                ]
    in
    Element.row [ I.classes classes ]
        (previewButton ++ cancelButton ++ retryButton ++ downloadButton)


previewMsg : Options msg -> FileInfo -> Maybe msg
previewMsg opts file =
    Maybe.map (\toMsg -> toMsg file.id) opts.onPreview


onRemoveMsg : Options msg -> FileInfo -> Maybe msg
onRemoveMsg opts file =
    Maybe.map (\toMsg -> toMsg file.id) opts.onRemove


onRetryMsg : Options msg -> FileInfo -> Maybe msg
onRetryMsg opts file =
    Maybe.map (\toMsg -> toMsg file.id) opts.onRetry


onDownloadMsg : Options msg -> FileInfo -> Maybe msg
onDownloadMsg opts file =
    Maybe.map (\toMsg -> toMsg file.id) opts.onDownload


{-| An action button: quaternary, kind-keyed, icon-only, carrying Naive UI's
`builtinThemeOverrides` (the `varOverrides` seam).
-}
uploadButton : Theme -> T.Kind -> Element msg -> Maybe msg -> Element msg
uploadButton theme kind iconEl onPress =
    let
        buttonDefaults =
            Button.defaults
    in
    Button.view theme
        { buttonDefaults
            | variant = Button.Quaternary
            , kind = kind
            , icon = Just iconEl
            , onPress = onPress
            , varOverrides = actionButtonOverrides
        }
        []


actionButtonOverrides : List ( String, String )
actionButtonOverrides =
    [ ( "--n-padding", "0 3px" )
    , ( "--n-height", "24px" )
    , ( "--n-icon-size", "18px" )
    ]


{-| `NUploadProgress` with `show = (status === 'uploading')` — a line bar at
height 2 with no indicator (the fade wrapper adds no element).
-}
progressNode : Theme -> FileInfo -> Element msg
progressNode theme file =
    let
        progressDefaults =
            Progress.defaults
    in
    Progress.view theme
        { progressDefaults
            | type_ = Progress.Line
            , showIndicator = False
            , percentage = toFloat (Maybe.withDefault 0 file.percentage)
            , status = progressStatusOf file.status
            , height = Just 2
        }
        []


{-| An `NBaseIcon` wrapper around a glyph — `i.n-base-icon` > svg.
-}
baseIconElement : Html.Html msg -> Element msg
baseIconElement svg =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ svg ])


{-| There is no public `Element` → `Html`, so a caller's element (or the nested
`NImage`) is embedded through `Element.layoutWith` (`display: contents`, the
`NUI.Input` / `NUI.Scrollbar` `embedChild` idiom).
-}
embedEl : Element msg -> Html.Html msg
embedEl el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el



-- ICONS (9 glyphs, wrapped in NBaseIcon; bytes verbatim from upstream) ----------


{-| `_internal/icons/Attach.tsx` (viewBox 0 0 16 16).
-}
attachSvg : Html.Html msg
attachSvg =
    squareIcon (Svg.node "path" [ HA.attribute "d" attachPath ] [])


attachPath : String
attachPath =
    "M3.25735931,8.70710678 L7.85355339,4.1109127 C8.82986412,3.13460197 10.4127766,3.13460197 11.3890873,4.1109127 C12.365398,5.08722343 12.365398,6.67013588 11.3890873,7.64644661 L6.08578644,12.9497475 C5.69526215,13.3402718 5.06209717,13.3402718 4.67157288,12.9497475 C4.28104858,12.5592232 4.28104858,11.9260582 4.67157288,11.5355339 L9.97487373,6.23223305 C10.1701359,6.0369709 10.1701359,5.72038841 9.97487373,5.52512627 C9.77961159,5.32986412 9.4630291,5.32986412 9.26776695,5.52512627 L3.96446609,10.8284271 C3.18341751,11.6094757 3.18341751,12.8758057 3.96446609,13.6568542 C4.74551468,14.4379028 6.01184464,14.4379028 6.79289322,13.6568542 L12.0961941,8.35355339 C13.4630291,6.98671837 13.4630291,4.77064094 12.0961941,3.40380592 C10.7293591,2.0369709 8.51328163,2.0369709 7.14644661,3.40380592 L2.55025253,8 C2.35499039,8.19526215 2.35499039,8.51184464 2.55025253,8.70710678 C2.74551468,8.90236893 3.06209717,8.90236893 3.25735931,8.70710678 Z"


{-| `_internal/icons/Cancel.tsx` (viewBox 0 0 16 16).
-}
cancelIconSvg : Html.Html msg
cancelIconSvg =
    squareIcon (Svg.node "path" [ HA.attribute "d" cancelPath ] [])


cancelPath : String
cancelPath =
    "M2.58859116,2.7156945 L2.64644661,2.64644661 C2.82001296,2.47288026 3.08943736,2.45359511 3.2843055,2.58859116 L3.35355339,2.64644661 L8,7.293 L12.6464466,2.64644661 C12.8417088,2.45118446 13.1582912,2.45118446 13.3535534,2.64644661 C13.5488155,2.84170876 13.5488155,3.15829124 13.3535534,3.35355339 L8.707,8 L13.3535534,12.6464466 C13.5271197,12.820013 13.5464049,13.0894374 13.4114088,13.2843055 L13.3535534,13.3535534 C13.179987,13.5271197 12.9105626,13.5464049 12.7156945,13.4114088 L12.6464466,13.3535534 L8,8.707 L3.35355339,13.3535534 C3.15829124,13.5488155 2.84170876,13.5488155 2.64644661,13.3535534 C2.45118446,13.1582912 2.45118446,12.8417088 2.64644661,12.6464466 L7.293,8 L2.64644661,3.35355339 C2.47288026,3.17998704 2.45359511,2.91056264 2.58859116,2.7156945 L2.64644661,2.64644661 L2.58859116,2.7156945 Z"


{-| `_internal/icons/Download.tsx` (viewBox 0 0 16 16).
-}
downloadIconSvg : Html.Html msg
downloadIconSvg =
    squareIcon (Svg.node "path" [ HA.attribute "d" downloadPath ] [])


downloadPath : String
downloadPath =
    "M3.5,13 L12.5,13 C12.7761424,13 13,13.2238576 13,13.5 C13,13.7454599 12.8231248,13.9496084 12.5898756,13.9919443 L12.5,14 L3.5,14 C3.22385763,14 3,13.7761424 3,13.5 C3,13.2545401 3.17687516,13.0503916 3.41012437,13.0080557 L3.5,13 L12.5,13 L3.5,13 Z M7.91012437,1.00805567 L8,1 C8.24545989,1 8.44960837,1.17687516 8.49194433,1.41012437 L8.5,1.5 L8.5,10.292 L11.1819805,7.6109127 C11.3555469,7.43734635 11.6249713,7.4180612 11.8198394,7.55305725 L11.8890873,7.6109127 C12.0626536,7.78447906 12.0819388,8.05390346 11.9469427,8.2487716 L11.8890873,8.31801948 L8.35355339,11.8535534 C8.17998704,12.0271197 7.91056264,12.0464049 7.7156945,11.9114088 L7.64644661,11.8535534 L4.1109127,8.31801948 C3.91565056,8.12275734 3.91565056,7.80617485 4.1109127,7.6109127 C4.28447906,7.43734635 4.55390346,7.4180612 4.7487716,7.55305725 L4.81801948,7.6109127 L7.5,10.292 L7.5,1.5 C7.5,1.25454011 7.67687516,1.05039163 7.91012437,1.00805567 L8,1 L7.91012437,1.00805567 Z"


{-| The 16-viewBox wrapper shared by Attach / Cancel / Download.
-}
squareIcon : Svg.Svg msg -> Html.Html msg
squareIcon path =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ path ]
            ]
        ]


{-| `_internal/icons/Retry.tsx` (viewBox 0 0 512 512).
-}
retryIconSvg : Html.Html msg
retryIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M320,146s24.36-12-64-12A160,160,0,1,0,416,294"
            , HA.attribute "style" "fill: none; stroke: currentcolor; stroke-linecap: round; stroke-miterlimit: 10; stroke-width: 32px;"
            ]
            []
        , Svg.node "polyline"
            [ HA.attribute "points" "256 58 336 138 256 218"
            , HA.attribute "style" "fill: none; stroke: currentcolor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 32px;"
            ]
            []
        ]


{-| `_internal/icons/Trash.tsx` (viewBox 0 0 512 512).
-}
trashIconSvg : Html.Html msg
trashIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M432,144,403.33,419.74A32,32,0,0,1,371.55,448H140.46a32,32,0,0,1-31.78-28.26L80,144"
            , HA.attribute "style" trashStyle
            ]
            []
        , Svg.node "rect"
            [ HA.attribute "x" "32"
            , HA.attribute "y" "64"
            , HA.attribute "width" "448"
            , HA.attribute "height" "80"
            , HA.attribute "rx" "16"
            , HA.attribute "ry" "16"
            , HA.attribute "style" trashStyle
            ]
            []
        , Svg.node "line"
            [ HA.attribute "x1" "312"
            , HA.attribute "y1" "240"
            , HA.attribute "x2" "200"
            , HA.attribute "y2" "352"
            , HA.attribute "style" trashStyle
            ]
            []
        , Svg.node "line"
            [ HA.attribute "x1" "312"
            , HA.attribute "y1" "352"
            , HA.attribute "x2" "200"
            , HA.attribute "y2" "240"
            , HA.attribute "style" trashStyle
            ]
            []
        ]


trashStyle : String
trashStyle =
    "fill: none; stroke: currentcolor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 32px;"


{-| `_internal/icons/Eye.tsx` (viewBox 0 0 512 512).
-}
eyeIconSvg : Html.Html msg
eyeIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M255.66 112c-77.94 0-157.89 45.11-220.83 135.33a16 16 0 0 0-.27 17.77C82.92 340.8 161.8 400 255.66 400c92.84 0 173.34-59.38 221.79-135.25a16.14 16.14 0 0 0 0-17.47C428.89 172.28 347.8 112 255.66 112z"
            , HA.attribute "fill" "none"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            , HA.attribute "stroke-width" "32"
            ]
            []
        , Svg.node "circle"
            [ HA.attribute "cx" "256"
            , HA.attribute "cy" "256"
            , HA.attribute "r" "80"
            , HA.attribute "fill" "none"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-miterlimit" "10"
            , HA.attribute "stroke-width" "32"
            ]
            []
        ]


{-| `_internal/icons/Add.tsx` (viewBox 0 0 512 512) — the image-card trigger's
default content.
-}
addIconSvg : Html.Html msg
addIconSvg =
    Svg.node "svg"
        [ HA.attribute "width" "512"
        , HA.attribute "height" "512"
        , HA.attribute "viewBox" "0 0 512 512"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M256 112V400M400 256H112"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-width" "32"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            ]
            []
        ]


{-| Upload-local `renderImageIcon` (`icons.tsx:12`, viewBox 0 0 28 28).
-}
imageIconSvg : Html.Html msg
imageIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 28 28"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" "M21.75 3A3.25 3.25 0 0 1 25 6.25v15.5A3.25 3.25 0 0 1 21.75 25H6.25A3.25 3.25 0 0 1 3 21.75V6.25A3.25 3.25 0 0 1 6.25 3h15.5zm.583 20.4l-7.807-7.68a.75.75 0 0 0-.968-.07l-.084.07l-7.808 7.68c.183.065.38.1.584.1h15.5c.204 0 .4-.035.583-.1l-7.807-7.68l7.807 7.68zM21.75 4.5H6.25A1.75 1.75 0 0 0 4.5 6.25v15.5c0 .208.036.408.103.593l7.82-7.692a2.25 2.25 0 0 1 3.026-.117l.129.117l7.82 7.692c.066-.185.102-.385.102-.593V6.25a1.75 1.75 0 0 0-1.75-1.75zm-3.25 3a2.5 2.5 0 1 1 0 5a2.5 2.5 0 0 1 0-5zm0 1.5a1 1 0 1 0 0 2a1 1 0 0 0 0-2z"
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]


{-| Upload-local `renderDocumentIcon` (`icons.tsx:22`, viewBox 0 0 28 28).
-}
documentIconSvg : Html.Html msg
documentIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 28 28"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" "M6.4 2A2.4 2.4 0 0 0 4 4.4v19.2A2.4 2.4 0 0 0 6.4 26h15.2a2.4 2.4 0 0 0 2.4-2.4V11.578c0-.729-.29-1.428-.805-1.944l-6.931-6.931A2.4 2.4 0 0 0 14.567 2H6.4zm-.9 2.4a.9.9 0 0 1 .9-.9H14V10a2 2 0 0 0 2 2h6.5v11.6a.9.9 0 0 1-.9.9H6.4a.9.9 0 0 1-.9-.9V4.4zm16.44 6.1H16a.5.5 0 0 1-.5-.5V4.06l6.44 6.44z"
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]



-- CSS VARS ----------------------------------------------------------------------


{-| The raw `--n-*` custom properties the root attaches, in upstream
`cssVarsRef` order (16 vars). Exposed so the output can be asserted directly;
`view` uses exactly this.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            UploadTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-dragger-border", v.draggerBorder )
    , ( "--n-dragger-border-hover", v.draggerBorderHover )
    , ( "--n-dragger-color", v.draggerColor )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-item-color-hover", v.itemColorHover )
    , ( "--n-item-color-hover-error", v.itemColorHoverError )
    , ( "--n-item-disabled-opacity", v.itemDisabledOpacity )
    , ( "--n-item-icon-color", v.itemIconColor )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-text-color-error", v.itemTextColorError )
    , ( "--n-item-text-color-success", v.itemTextColorSuccess )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-item-border-image-card-error", v.itemBorderImageCardError )
    , ( "--n-item-border-image-card", v.itemBorderImageCard )
    ]
