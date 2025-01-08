module Page exposing (Msg(..), update, viewFooter, viewHeader, viewMessages)

import ApiResponse exposing (ApiResponse, apiResponseDecoder)
import Array
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, class, height, href, id, src, style, title, width)
import Html.Events exposing (onClick, onInput)
import Http
import Locale exposing (Locale)
import Message exposing (Message)
import Route exposing (Route(..))
import ServerRequest
import Session exposing (Session)
import Translations.Page as I18n
import User


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
                        newSession =
                            Session.setUser (User.fromToken "") session

                        newerSession =
                            Session.addMessage Message.getLoginSuccess newSession
                    in
                    ( newerSession, Cmd.none )

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


viewMessages : Session -> Html msg
viewMessages session =
    div [ class "container pt-3" ]
        (Array.toList (Array.indexedMap (viewMessage session) (Session.messages session)))


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


viewMessage : Session -> Int -> Message -> Html msg
viewMessage session index message =
    let
        t =
            (Session.locale session).t

        baseClass =
            "aes-message alert"

        ( severityClass, severityTitle ) =
            case Message.severity message of
                Message.Success ->
                    ( "alert-success", I18n.success t )

                Message.Info ->
                    ( "alert-info", I18n.info t )

                Message.Warning ->
                    ( "alert-warning", I18n.warning t )

                Message.Error ->
                    ( "alert-danger", I18n.error t )

        newClass =
            baseClass ++ " " ++ severityClass
    in
    div [ class newClass, attribute "role" "alert", id <| "aes-message-" ++ String.fromInt index ]
        [ h4 [ class "alert-heading text-center" ] [ text severityTitle ]
        , hr [] []
        , h5 [ class "alert-heading" ] [ text <| Message.title message t ]
        , text <| Message.text message t
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
        button
            [ title <| I18n.logoutTooltip t, onClick LogoutRequested, class "btn btn-secondary me-2" ]
            [ text "Logout   ", i [ class "bi bi-box-arrow-right" ] [] ]

    else
        div [] []


viewFooterLinks : Locale -> List (Html Msg)
viewFooterLinks locale =
    let
        routes =
            [ Route.Privacy, Route.Imprint ]

        routeToItem route =
            li
                []
                [ a
                    [ href <| Route.toHref route ]
                    [ button [ class "btn btn-secondary" ] [ text <| Route.toText route locale ] ]
                ]
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
