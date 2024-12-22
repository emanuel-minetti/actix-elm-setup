module Page.NotFound exposing (view)

import Html exposing (Html, br, div, h1, text)
import Html.Attributes exposing (class)
import Session exposing (Session)
import Translations.NotFound as I18n


view : Session -> Html msg
view session =
    let
        locale =
            Session.locale session
    in
    div [ class "container" ]
        [ h1 []
            [ text <| I18n.title locale.t ]
        , br [] []
        , text <| I18n.message locale.t
        ]
