module Page exposing (Msg(..), update, view)

import ApiResponse exposing (ApiResponse, apiResponseDecoder)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, src, style, title, width)
import Html.Events exposing (onClick, onInput)
import Http
import Locale exposing (Locale)
import Route exposing (Route(..))
import ServerRequest
import Session exposing (Session)
import Translations.Page as I18n
import User


view : Session -> ( Html Msg, Html Msg )
view session =
    ( viewHeader session, viewFooter session )


type Msg
    = SwitchLanguage String
    | GotTranslation Locale.Msg
    | LogoutRequested
    | GotLogout (Result Http.Error ApiResponse)


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

        LogoutRequested ->
            ( session, loadLogout session )

        GotLogout result ->
            case result of
                Ok _ ->
                    let
                        preferredLocale =
                            session
                                |> Session.user
                                |> User.preferredLocale

                        newSession =
                            Session.setUser (User.fromTokenAndLocale "" preferredLocale) session
                    in
                    ( newSession, Cmd.none )

                Err _ ->
                    ( session, Cmd.none )


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
                , div [ style "display" "flex" ]
                    [ viewLoginInfo session
                    , select [ onInput SwitchLanguage ] (Locale.viewLangOptions (Session.locale session))
                    ]
                ]
            ]
        ]


viewLoggedInText : Session -> Html Msg
viewLoggedInText session =
    let
        t =
            (Session.locale session).t

        loggedIn =
            Session.isLoggedIn session

        loggedInText =
            if not loggedIn then
                I18n.notLoggedInText t

            else
                I18n.loggedInText t <| User.name <| Session.user session
    in
    text loggedInText


viewLoginInfo : Session -> Html Msg
viewLoginInfo session =
    let
        t =
            (Session.locale session).t

        loggedIn =
            Session.isLoggedIn session
    in
    if loggedIn then
        h4 [ title <| I18n.logoutTooltip t, onClick LogoutRequested ] [ i [ class "bi bi-box-arrow-right me-3" ] [] ]

    else
        div [] []


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


loadLogout : Session -> Cmd Msg
loadLogout session =
    let
        token =
            session
                |> Session.user
                |> User.token
    in
    ServerRequest.logout token <| Http.expectJson GotLogout apiResponseDecoder
