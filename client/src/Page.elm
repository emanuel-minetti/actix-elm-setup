module Page exposing (Msg(..), update, viewExpirationModal, viewFooter, viewHeader, viewMessages)

import ApiResponse exposing (ApiResponse, apiResponseDecoder)
import Array
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, class, height, href, id, src, style, tabindex, title, type_, width)
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
    | RenewSession
    | GotRenewedSession (Result Http.Error ApiResponse)



--PLATFORM


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

        RenewSession ->
            ( session, loadSession session )

        GotRenewedSession result ->
            case result of
                Ok apiResponse ->
                    let
                        newSession =
                            session
                                |> Session.user
                                |> User.setExpiresAt apiResponse.expires
                                |> Session.setUser
                    in
                    ( newSession session, Cmd.none )

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


viewExpirationModal : Session -> Html Msg
viewExpirationModal session =
    let
        t =
            (Session.locale session).t
    in
    div
        [ class "modal fade"
        , id "expirationModal"
        , tabindex -1
        , attribute "aria-labelledby" "expirationModalLabel"
        , attribute "aria-hidden" "true"
        ]
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h1 [ class "modal-title fs-5", id "expirationModalLabel" ] [ text <| I18n.modalTitle t ]
                    , button
                        [ type_ "button"
                        , class "btn-close"
                        , attribute "data-bs-dismiss" "modal"
                        , attribute "aria-label" "Close"
                        ]
                        []
                    ]
                , div [ class "modal-body" ]
                    [ text <| I18n.modalBody t ]
                , div [ class "modal-footer" ]
                    [ button
                        [ type_ "button"
                        , class "btn btn-secondary"
                        , attribute "data-bs-dismiss" "modal"
                        , onClick LogoutRequested
                        ]
                        [ text <| I18n.modalLogout t ]
                    , button
                        [ type_ "button"
                        , class "btn btn-primary"
                        , attribute "data-bs-dismiss" "modal"
                        , onClick RenewSession
                        ]
                        [ text <| I18n.modalRenew t ]
                    ]
                ]
            ]
        ]


viewMessages : Session -> Html msg
viewMessages session =
    div [ class "container pt-3", id "messages" ]
        (Array.toList (Array.indexedMap (viewMessage session) (Session.messages session)))


viewFooter : Session -> Html Msg
viewFooter session =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] <| viewFooterLinks <| Session.locale session ]
                , div [ class "col text-center" ]
                    [ span [] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]



--PRIVATE


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
        let
            expiresAt =
                session
                    |> Session.user
                    |> User.expiresAt
                    |> (*) 1000

            currentTime =
                session
                    |> Session.currentTime

            remainingMinutes =
                toFloat (expiresAt - currentTime)
                    / (1000 * 60)
                    |> round
                    |> String.fromInt
        in
        [ button
            [ title <|
                I18n.remainingTooltip t remainingMinutes
            , onClick RenewSession
            , class "btn btn-outline-secondary me-2"
            ]
            [ text remainingMinutes ]
        , button
            [ title <| I18n.logoutTooltip t, onClick LogoutRequested, class "btn btn-outline-secondary me-2" ]
            [ i [ class "bi bi-box-arrow-right fw-bold" ] [] ]
        ]
            |> div []

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


loadSession : Session -> Cmd Msg
loadSession session =
    let
        tokenToLoad =
            session
                |> Session.user
                |> User.token
    in
    ServerRequest.loadSession tokenToLoad <| Http.expectJson GotRenewedSession apiResponseDecoder
