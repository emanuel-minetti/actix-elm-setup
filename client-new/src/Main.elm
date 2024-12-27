port module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Locale exposing (Locale)
import Page
import Page.Home
import Page.Imprint
import Page.Login
import Page.NotFound
import Page.Privacy
import Route exposing (Route(..))
import Session exposing (Session, locale)
import Url exposing (Url)
import User


port setLang : String -> Cmd msg


port setToken : String -> Cmd msg


type Model
    = Init Session
    | Home Page.Home.Model
    | Login Page.Login.Model
    | NotFound Session
    | Imprint Session
    | Privacy Session


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LocaleMsg Locale.Msg
    | PageMsg Page.Msg
    | UserMsg User.Msg
    | HomeMsg Page.Home.Msg
    | LoginMsg Page.Login.Msg


main : Program (Array String) Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }


init : Array String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        defaultLangString =
            "de"

        langFromBrowser =
            Maybe.withDefault defaultLangString <| Array.get 0 flags

        ( locale, localeCmd ) =
            Locale.init langFromBrowser

        tokenFromBrowser =
            Maybe.withDefault "" <| Array.get 1 flags

        ( user, userCmd ) =
            User.init tokenFromBrowser locale

        route =
            Route.parseUrl url

        session =
            Session.init locale navKey user

        ( model, modelCmd ) =
            changeRoute route <| Init session

        cmds =
            [ Cmd.map LocaleMsg localeCmd, Cmd.map UserMsg userCmd, modelCmd ]
    in
    ( model, Cmd.batch cmds )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ChangedUrl url ->
            let
                newRoute =
                    Route.parseUrl url
            in
            changeRoute newRoute model

        LocaleMsg localeCmd ->
            let
                session =
                    toSession model

                ( locale, _ ) =
                    Locale.update localeCmd <| Session.locale session

                newSession =
                    Session.setLocale locale session

                newModel =
                    setNewSession newSession model
            in
            ( newModel, Cmd.none )

        PageMsg pageMsg ->
            let
                session =
                    toSession model

                ( newSession, newPageCmd ) =
                    Page.update pageMsg session

                newerSession =
                    Session.setLocale (Session.locale newSession) newSession

                newModel =
                    setNewSession newerSession model

                cmd =
                    case pageMsg of
                        Page.SwitchLanguage lang ->
                            let
                                storageCmd =
                                    setLang lang

                                apiCmd =
                                    User.setSession (User.token <| Session.user newSession) lang
                            in
                            Cmd.batch [ Cmd.map PageMsg newPageCmd, Cmd.map UserMsg apiCmd, storageCmd ]

                        Page.GotTranslation _ ->
                            Cmd.map PageMsg newPageCmd
            in
            ( newModel, cmd )

        UserMsg userMsg ->
            let
                session =
                    toSession model

                ( newUser, userCmd ) =
                    User.update userMsg <| Session.user session

                ( newerModel, cmd ) =
                    case userMsg of
                        User.GotApiLoadResponse result ->
                            case result of
                                Ok _ ->
                                    let
                                        newSession =
                                            Session.setUser newUser session

                                        newModel =
                                            setNewSession newSession model

                                        storageCmd =
                                            newUser
                                                |> User.preferredLocale
                                                |> Locale.toValue
                                                |> setLang

                                        redirectCmd =
                                            case model of
                                                Login loginModel ->
                                                    if Session.isLoggedIn newSession then
                                                        let
                                                            redirect =
                                                                if loginModel.redirect == Route.Login then
                                                                    Route.Home

                                                                else
                                                                    loginModel.redirect
                                                        in
                                                        Nav.pushUrl (Session.navKey session) (Route.toHref redirect)

                                                    else
                                                        Cmd.none

                                                _ ->
                                                    Cmd.none

                                        newCmd =
                                            Cmd.batch [ Cmd.map UserMsg userCmd, storageCmd, redirectCmd ]
                                    in
                                    ( newModel, newCmd )

                                Err _ ->
                                    ( model, Cmd.none )

                        User.GotApiSetResponse _ ->
                            ( model, Cmd.none )

                        User.GotTranslationFromLocale _ ->
                            let
                                newSession =
                                    if Session.locale session == User.preferredLocale newUser then
                                        Session.setUser newUser session

                                    else
                                        session
                                            |> Session.setUser newUser
                                            |> Session.setLocale (User.preferredLocale newUser)

                                newModel =
                                    setNewSession newSession model
                            in
                            ( newModel, Cmd.none )
            in
            ( newerModel, cmd )

        LoginMsg loginMsg ->
            case model of
                Login loginModel ->
                    let
                        ( newLoginModel, newLoginCmd ) =
                            Page.Login.update loginMsg loginModel

                        newModel =
                            Login newLoginModel

                        cmd =
                            case loginMsg of
                                Page.Login.GotLoginResponse result ->
                                    case result of
                                        Ok _ ->
                                            --get session from server, store token in browser and redirect
                                            let
                                                session =
                                                    newModel
                                                        |> toSession

                                                token =
                                                    session
                                                        |> Session.user
                                                        |> User.token

                                                userCmd =
                                                    User.loadSession token

                                                storageCmd =
                                                    setToken token

                                                redirect =
                                                    if loginModel.redirect == Route.Login then
                                                        Route.Home

                                                    else
                                                        loginModel.redirect

                                                redirectCmd =
                                                    Nav.pushUrl (Session.navKey session) (Route.toHref redirect)
                                            in
                                            Cmd.batch
                                                [ Cmd.map LoginMsg newLoginCmd
                                                , Cmd.map UserMsg userCmd
                                                , storageCmd
                                                , redirectCmd
                                                ]

                                        Err _ ->
                                            Cmd.map LoginMsg newLoginCmd

                                _ ->
                                    Cmd.map LoginMsg newLoginCmd
                    in
                    ( newModel, cmd )

                _ ->
                    ( model, Cmd.none )

        HomeMsg _ ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    let
        session =
            toSession model

        ( header, footer ) =
            Page.view session

        viewPage newTitle content =
            let
                newerTitle =
                    "AES - " ++ newTitle

                newBody =
                    [ Html.map PageMsg header, content, Html.map PageMsg footer ]
            in
            ( newerTitle, newBody )

        ( title, body ) =
            case model of
                Home homeModel ->
                    viewPage "Home" <| Html.map HomeMsg <| Page.Home.view homeModel

                NotFound _ ->
                    viewPage "NotFound" <| Page.NotFound.view session

                Imprint _ ->
                    viewPage "Imprint" <| Page.Imprint.view session

                Privacy _ ->
                    viewPage "Privacy" <| Page.Privacy.view session

                Login loginModel ->
                    viewPage "Login" <| Html.map LoginMsg <| Page.Login.view loginModel

                Init _ ->
                    viewPage "" <| Html.text ""
    in
    { title = title, body = body }


toSession : Model -> Session
toSession model =
    case model of
        Home homeModel ->
            Page.Home.toSession homeModel

        NotFound session ->
            session

        Imprint session ->
            session

        Privacy session ->
            session

        Login loginModel ->
            Page.Login.toSession loginModel

        Init session ->
            session


setNewSession : Session -> Model -> Model
setNewSession session model =
    case model of
        Home homeModel ->
            Home <| Page.Home.setSession session homeModel

        NotFound _ ->
            NotFound session

        Imprint _ ->
            Imprint session

        Privacy _ ->
            Privacy session

        Login loginModel ->
            Login <| Page.Login.setSession session loginModel

        Init _ ->
            Init session


changeRoute : Route -> Model -> ( Model, Cmd Msg )
changeRoute route model =
    let
        session =
            toSession model
    in
    if Route.needsAuthentication route && not (Session.isLoggedIn session) then
        let
            ( loginModel, _ ) =
                Page.Login.init session route

            cmd =
                Nav.pushUrl (Session.navKey session) (Route.toHref Route.Login)
        in
        ( Login loginModel, cmd )

    else
        case route of
            Route.NotFound ->
                ( NotFound session, Cmd.none )

            Route.Home ->
                let
                    ( homeModel, homeCmd ) =
                        Page.Home.init session
                in
                ( Home homeModel, Cmd.map HomeMsg homeCmd )

            Route.Privacy ->
                ( Privacy session, Cmd.none )

            Route.Imprint ->
                ( Imprint session, Cmd.none )

            Route.Login ->
                let
                    newLoginModel =
                        case model of
                            Login loginModel ->
                                loginModel

                            _ ->
                                Tuple.first <| Page.Login.init session Route.Login
                in
                ( Login newLoginModel, Cmd.none )
