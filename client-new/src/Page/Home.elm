module Page.Home exposing (Msg(..), view)

import Html exposing (Html, br, div, h1, text)
import Html.Attributes exposing (class)
import Locale
import Session exposing (Session)
import Translations.Home as I18n


type Msg
    = None


view : Session -> Html Msg
view session =
    let
        locale =
            Session.locale session
    in
    div [ class "container" ]
        [ h1 []
            [ text <| I18n.title locale.t ]
        , br [] []
        , text <| I18n.yourPreferredLang locale.t <| Locale.toValue <| locale
        ]
