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


type Model
    = Home Page.Home.Model
    | Login Page.Login.Model
    | NotFound Session
    | Imprint Session
    | Privacy Session


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslationFromLocale Locale.Msg
    | GotTranslationFromPage Page.Msg
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
            User.init tokenFromBrowser

        route =
            Route.parseUrl url

        session =
            Session.init locale navKey user

        ( model, newCmd ) =
            case route of
                Route.NotFound ->
                    ( NotFound session, Cmd.none )

                Route.Home ->
                    let
                        ( homeModel, homeMsg ) =
                            Page.Home.init session
                    in
                    ( Home homeModel, Cmd.map HomeMsg homeMsg )

                Route.Privacy ->
                    ( Privacy session, Cmd.none )

                Route.Imprint ->
                    ( Imprint session, Cmd.none )

                Route.Login ->
                    let
                        ( loginModel, _ ) =
                            Page.Login.init session Route.Home
                    in
                    ( Login loginModel, Cmd.none )

        cmds =
            [ Cmd.map GotTranslationFromLocale localeCmd, Cmd.map UserMsg userCmd, newCmd ]
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

        GotTranslationFromLocale localeCmd ->
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

        GotTranslationFromPage pageCmd ->
            let
                session =
                    toSession model

                ( newSession, _ ) =
                    Page.update pageCmd session

                newerSession =
                    Session.setLocale (Session.locale newSession) newSession

                newModel =
                    setNewSession newerSession model
            in
            ( newModel, Cmd.none )

        PageMsg pageMsg ->
            case pageMsg of
                Page.SwitchLanguage lang ->
                    let
                        session =
                            toSession model

                        ( newSession, newPageCmd ) =
                            Page.update pageMsg session

                        newerSession =
                            Session.setLocale (Session.locale newSession) newSession

                        newModel =
                            setNewSession newerSession model

                        storageCmd =
                            setLang lang

                        apiCmd =
                            User.setSession (User.token <| Session.user newSession) lang

                        newCmd =
                            Cmd.batch
                                [ Cmd.map GotTranslationFromPage newPageCmd
                                , Cmd.map UserMsg apiCmd
                                , storageCmd
                                ]
                    in
                    ( newModel, newCmd )

                Page.GotTranslation _ ->
                    ( model, Cmd.none )

        UserMsg userMsg ->
            case userMsg of
                User.GotApiLoadResponse _ ->
                    let
                        session =
                            toSession model

                        ( newUser, userCmd ) =
                            User.update userMsg <| Session.user session

                        newSession =
                            Session.setUser newUser session

                        newModel =
                            setNewSession newSession model

                        storageCmd =
                            newUser
                                |> User.preferredLocale
                                |> Locale.toValue
                                |> setLang

                        newCmd =
                            Cmd.batch [ storageCmd, Cmd.map UserMsg userCmd ]
                    in
                    ( newModel, newCmd )

                User.GotApiSetResponse _ ->
                    ( model, Cmd.none )

                User.GotTranslationFromLocale _ ->
                    let
                        session =
                            toSession model

                        ( newUser, _ ) =
                            User.update userMsg <| Session.user session

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

        HomeMsg homeMsg ->
            case homeMsg of
                Page.Home.None ->
                    ( model, Cmd.none )

                Page.Home.NotLoggedIn ->
                    let
                        ( loginModel, _ ) =
                            Page.Login.init (toSession model) Route.Home
                    in
                    changeRoute Route.Login <| Login loginModel

        LoginMsg loginMsg ->
            case loginMsg of
                Page.Login.None ->
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
                    viewPage "Login" <| Page.Login.view loginModel
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


changeRoute : Route -> Model -> ( Model, Cmd Msg )
changeRoute route model =
    let
        session =
            toSession model
    in
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
                ( loginModel, _ ) =
                    Page.Login.init session route
            in
            ( Login loginModel, Cmd.none )
