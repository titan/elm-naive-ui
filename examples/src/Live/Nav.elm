module Live.Nav exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the nav family: Tabs, Collapse, Menu, Pagination, Steps, Anchor, BackTop, Split.

Caller-owned state per the port's contract: the component renders whatever the
model says; every channel feeds one Msg constructor.

-}

import Element exposing (Element)
import NUI.Theme exposing (Theme)


type Model
    = Model


init : Model
init =
    Model


type Msg
    = Noop


update : Msg -> Model -> Model
update _ model =
    model


view : Theme -> Model -> Element Msg
view _ _ =
    Element.none


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
