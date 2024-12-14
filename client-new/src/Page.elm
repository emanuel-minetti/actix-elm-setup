module Page exposing (Msg(..), update, view)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, src, width)
import Html.Events exposing (onInput)
import Locale exposing (Locale)
import Route exposing (Route(..))
import Session exposing (Session)
import Translations.Main as I18n


view : Session -> Document Msg
view session =
    { title = Route.toText session.route session.locale
    , body = [ viewHeader session, viewContent session, viewFooter session ]
    }


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


viewContent : Session -> Html Msg
viewContent session =
    case session.route of
        Home ->
            div [ class "container" ]
                [ text "Das ist Home"
                , br [] []
                , text <| I18n.yourPreferredLang session.locale.t <| Locale.toValue session.locale
                ]

        NotFound ->
            div [ class "container" ]
                [ text "Das ist NotFound"
                , br [] []
                , text <| I18n.yourPreferredLang session.locale.t <| Locale.toValue session.locale
                ]

        Privacy ->
            div [ class "container" ]
                [ text "Das ist Privacy"
                , br [] []
                , text <| I18n.yourPreferredLang session.locale.t <| Locale.toValue session.locale
                ]

        Imprint ->
            div [ class "container" ]
                [ text "Das ist Imprint"
                , br [] []
                , text <| I18n.yourPreferredLang session.locale.t <| Locale.toValue session.locale
                ]


viewFooter : Session -> Html Msg
viewFooter model =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] <| viewFooterLinks model.locale ]
                , div [ class "col text-center" ]
                    --todo get from config api
                    [ span [] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]


viewFooterLinks : Locale -> List (Html Msg)
viewFooterLinks locale =
    let
        routes =
            [ Route.Privacy, Route.Imprint ]

        routeToItem route =
            li [] [ a [ href <| Route.toHref route ] [ button [ class "btn btn-secondary" ] [ text <| Route.toText route locale ] ] ]
    in
    List.map routeToItem routes
