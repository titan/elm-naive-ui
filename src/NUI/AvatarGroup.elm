module NUI.AvatarGroup exposing
    ( AvatarGroupOption
    , Options
    , defaults
    , view
    )

{-| Naive UI's `AvatarGroup`, rebuilt on elm-ui.

    NUI.AvatarGroup.view theme
        { NUI.AvatarGroup.defaults | max = Just 3 }
        [ { src = "https://example.com/a.png" }
        , { src = "https://example.com/b.png" }
        , { src = "https://example.com/c.png" }
        , { src = "https://example.com/d.png" }
        ]
        -- renders a, b, then an avatar reading "+2"

The group is Naive UI's own markup — `div.n-avatar-group` (`role="group"`) with
the `--vertical` / `--expand-on-hover` / `--rtl` modifiers and the `--n-gap`
custom property — so the extracted CSS overlaps the avatars exactly as
upstream.

**Size, round and bordered are applied by the group.** Naive UI forces every
`NAvatar` inside a group to be round and bordered, and injects the group's
`size` for avatars that do not set their own. Because this library renders those
avatars itself (from `options`), the same forcing is applied here: `round` and
`bordered` are always `True` and `size` defaults to the group's (or `Medium`).

**Slots.** `avatar` / `rest` mirror upstream's `$slots.avatar` / `$slots.rest`
and replace the built-in rendering entirely. `maxStyle` is Naive UI's `max-style`
prop in its `CSSProperties` form (a `( "prop", "value" )` list); upstream's
raw-string alternative is not modelled.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Avatar as Avatar
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.AvatarGroup as AvatarGroupTheme


{-| One entry of Naive UI's `options` prop. Upstream only reads `src`, which the
built-in rendering passes to `NUI.Avatar`.
-}
type alias AvatarGroupOption =
    { src : String }


type alias Options msg =
    { max : Maybe Int
    , maxStyle : List ( String, String )
    , vertical : Bool
    , expandOnHover : Bool
    , size : Maybe Avatar.AvatarSize
    , rtl : Bool
    , avatar : Maybe (AvatarGroupOption -> Element msg)
    , rest : Maybe (List AvatarGroupOption -> Int -> Element msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { max = Nothing
    , maxStyle = []
    , vertical = False
    , expandOnHover = False
    , size = Nothing
    , rtl = False
    , avatar = Nothing
    , rest = Nothing
    , attributes = []
    }


{-| The group container. `options` are the avatars in order; with `max` set, the
overflow collapses into a single `+N` avatar at the end.
-}
view : Theme -> Options msg -> List AvatarGroupOption -> Element msg
view theme opts options =
    let
        v =
            AvatarGroupTheme.vars theme

        ( displayed, restOptions ) =
            case opts.max of
                Nothing ->
                    ( options, Nothing )

                Just max ->
                    if List.length options > max then
                        ( List.take (max - 1) options
                        , Just (List.drop (max - 1) options)
                        )

                    else
                        ( options, Nothing )

        body =
            List.map (renderAvatar theme opts) displayed
                ++ (case restOptions of
                        Just rest ->
                            [ renderRest theme opts rest (List.length rest) ]

                        Nothing ->
                            []
                   )
    in
    Element.row
        ([ I.classes
            ("n-avatar-group"
                :: I.classIf opts.rtl "n-avatar-group--rtl"
                ++ I.classIf opts.vertical "n-avatar-group--vertical"
                ++ I.classIf opts.expandOnHover "n-avatar-group--expand-on-hover"
            )
         , I.cssVars [ ( "--n-gap", v.gap ) ]
         , Element.htmlAttribute (HA.attribute "role" "group")
         ]
            ++ opts.attributes
        )
        body


{-| One avatar: the `avatar` slot if given, otherwise an `NAvatar` carrying the
option's `src`.
-}
renderAvatar : Theme -> Options msg -> AvatarGroupOption -> Element msg
renderAvatar theme opts option =
    case opts.avatar of
        Just slot ->
            slot option

        Nothing ->
            Avatar.view theme (avatarOptions opts (Just option.src) []) []


{-| The overflow avatar: the `rest` slot if given, otherwise an `NAvatar` reading
`+N` and carrying `maxStyle`.
-}
renderRest : Theme -> Options msg -> List AvatarGroupOption -> Int -> Element msg
renderRest theme opts restOptions count =
    case opts.rest of
        Just slot ->
            slot restOptions count

        Nothing ->
            Avatar.view theme
                (avatarOptions opts Nothing (maxStyleAttributes opts.maxStyle))
                [ Element.text ("+" ++ String.fromInt count) ]


{-| The `NAvatar.Options` the group forces: round, bordered and sized by the
group, matching Naive UI's avatar-group injection.
-}
avatarOptions : Options msg -> Maybe String -> List (Element.Attribute msg) -> Avatar.Options msg
avatarOptions opts src extraAttributes =
    { size = Maybe.withDefault Avatar.Medium opts.size
    , round = True
    , circle = False
    , bordered = True
    , color = Nothing
    , src = src
    , attributes = extraAttributes
    }


maxStyleAttributes : List ( String, String ) -> List (Element.Attribute msg)
maxStyleAttributes pairs =
    List.map (\( key, value ) -> Element.htmlAttribute (HA.style key value)) pairs
