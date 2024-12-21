port module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Locale exposing (Locale)
import Page
import Route exposing (Route(..))
import Session exposing (Session, locale)
import Url exposing (Url)
import User


port setLang : String -> Cmd msg


type alias Model =
    Session


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslationFromLocale Locale.Msg
    | GotTranslationFromPage Page.Msg
    | PageMsg Page.Msg
    | UserMsg User.Msg


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

        model =
            Session.init locale (Route.parseUrl url) navKey user

        --Session
        --    { locale = locale
        --    , route = Route.parseUrl url
        --    , navKey = navKey
        --    , user = user
        --    }
        cmds =
            [ Cmd.map GotTranslationFromLocale localeCmd, Cmd.map UserMsg userCmd ]
    in
    ( model, Cmd.batch cmds )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (Session.navKey model) (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ChangedUrl url ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( Session.setRoute model newRoute, Cmd.none )

        GotTranslationFromLocale localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd <| Session.locale model
            in
            ( Session.setLocale model locale, Cmd.none )

        GotTranslationFromPage pageCmd ->
            let
                ( session, _ ) =
                    Page.update pageCmd model
            in
            ( Session.setLocale model (Session.locale session), Cmd.none )

        --( { model | locale = session.locale }, Cmd.none )
        PageMsg pageMsg ->
            case pageMsg of
                Page.SwitchLanguage lang ->
                    let
                        ( session, newPageCmd ) =
                            Page.update pageMsg model

                        storageCmd =
                            setLang lang

                        apiCmd =
                            User.setSession (User.token <| Session.user session) lang

                        newCmd =
                            Cmd.batch
                                [ Cmd.map GotTranslationFromPage newPageCmd
                                , Cmd.map UserMsg apiCmd
                                , storageCmd
                                ]

                        newModel =
                            Session.setLocale model <| Session.locale session
                    in
                    ( newModel, newCmd )

                Page.GotTranslation _ ->
                    ( model, Cmd.none )

        UserMsg userMsg ->
            case userMsg of
                User.GotApiLoadResponse _ ->
                    let
                        ( newUser, userCmd ) =
                            User.update userMsg <| Session.user model

                        storageCmd =
                            newUser
                                |> User.preferredLocale
                                |> Locale.toValue
                                |> setLang

                        newModel =
                            Session.setUser model newUser

                        newCmd =
                            Cmd.batch [ storageCmd, Cmd.map UserMsg userCmd ]
                    in
                    ( newModel, newCmd )

                User.GotApiSetResponse _ ->
                    ( model, Cmd.none )

                User.GotTranslationFromLocale _ ->
                    let
                        ( newUser, _ ) =
                            User.update userMsg <| Session.user model

                        newModel =
                            if Session.locale model == User.preferredLocale newUser then
                                Session.setUser model newUser

                            else
                                Session.setLocale (Session.setUser model newUser) <| User.preferredLocale newUser
                    in
                    ( newModel, Cmd.none )


view : Model -> Document Msg
view model =
    let
        { title, body } =
            Page.view model
    in
    { title = title, body = List.map (Html.map PageMsg) body }
