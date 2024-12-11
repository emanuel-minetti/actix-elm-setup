module Page exposing (Msg(..), update, viewHeader)

--import Browser exposing (Document)
--import Route

import Html exposing (Html, a, div, header, img, nav, select, span, text)
import Html.Attributes exposing (alt, class, height, href, src, width)
import Html.Events exposing (onInput)
import Locale
import Session exposing (Session)
import Translations.Main as I18n



--view : Session -> Document msg
--view session =
--    { title = Route.toText session.route session.locale
--    , body = [ viewHeader session ]
--    }


type Msg
    = SwitchLanguage String
    | GotTranslation Locale.Msg


update : Msg -> Session -> ( Session, Cmd Msg )
update msg session =
    case msg of
        SwitchLanguage newValue ->
            let
                locale =
                    Locale.changeLang session.locale newValue
            in
            ( { session | locale = locale }, Cmd.map GotTranslation <| Locale.loadTranslation locale )

        GotTranslation localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd session.locale
            in
            ( { session | locale = locale }, Cmd.none )


viewHeader : Session -> Html Msg
viewHeader session =
    header []
        [ nav [ class "navbar bg-body-tertiary" ]
            [ div [ class "container-fluid" ]
                [ a
                    [ class "navbar-brand", href "/" ]
                    [ img
                        [ src "img/logo-color.png"
                        , alt "Logo"
                        , width 30
                        , height 24
                        , class "d-inline-block align-text-top me-3"
                        ]
                        []
                    , text "Actix Elm Setup"
                    ]
                , span [ class "navbar-text" ] [ text <| I18n.loggedInText session.locale.t ]
                , select [ onInput SwitchLanguage ] <| Locale.viewLangOptions session.locale
                ]
            ]
        ]
