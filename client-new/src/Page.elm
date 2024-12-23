module Page exposing (Msg(..), update, view)

import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, src, width)
import Html.Events exposing (onInput)
import Locale exposing (Locale)
import Route exposing (Route(..))
import Session exposing (Session)
import Translations.Main as I18n
import User


view : Session -> ( Html Msg, Html Msg )
view session =
    ( viewHeader session, viewFooter session )


type Msg
    = SwitchLanguage String
    | GotTranslation Locale.Msg


update : Msg -> Session -> ( Session, Cmd Msg )
update msg session =
    case msg of
        SwitchLanguage newValue ->
            let
                locale =
                    Locale.changeLang (Session.locale session) newValue
            in
            ( Session.setLocale locale session, Cmd.map GotTranslation <| Locale.loadTranslation locale )

        GotTranslation localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd (Session.locale session)
            in
            ( Session.setLocale locale session, Cmd.none )


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
                , span [ class "navbar-text" ] [ viewLoggedInText session ]
                , select [ onInput SwitchLanguage ] (Locale.viewLangOptions (Session.locale session))
                ]
            ]
        ]


viewLoggedInText : Session -> Html Msg
viewLoggedInText session =
    let
        loggedIn =
            Session.isLoggedIn session

        loggedInText =
            if not loggedIn then
                I18n.notLoggedInText (Session.locale session).t

            else
                I18n.loggedInText (Session.locale session).t <| User.name <| Session.user session
    in
    text loggedInText


viewFooter : Session -> Html Msg
viewFooter session =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] <| viewFooterLinks <| Session.locale session ]
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
