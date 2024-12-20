port module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Locale exposing (Locale)
import Page
import Route exposing (Route(..))
import Session exposing (Session)
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
            { locale = locale
            , route = Route.parseUrl url
            , navKey = navKey
            , user = user
            }

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
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ChangedUrl url ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )

        GotTranslationFromLocale localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd model.locale
            in
            ( { model | locale = locale }, Cmd.none )

        GotTranslationFromPage pageCmd ->
            let
                ( session, _ ) =
                    Page.update pageCmd model
            in
            ( { model | locale = session.locale }, Cmd.none )

        PageMsg pageMsg ->
            case pageMsg of
                Page.SwitchLanguage lang ->
                    let
                        ( session, newPageCmd ) =
                            Page.update pageMsg model

                        storageCmd =
                            setLang lang

                        dbCmd =
                            User.setSession (User.token model.user) lang

                        newCmd =
                            Cmd.batch
                                [ Cmd.map GotTranslationFromPage newPageCmd
                                , Cmd.map UserMsg dbCmd
                                , storageCmd
                                ]
                    in
                    ( { model | locale = session.locale }, newCmd )

                Page.GotTranslation _ ->
                    ( model, Cmd.none )

        UserMsg userMsg ->
            case userMsg of
                User.GotApiLoadResponse _ ->
                    let
                        ( newUser, userCmd ) =
                            User.update userMsg model.user
                    in
                    ( { model | user = newUser }, Cmd.map UserMsg userCmd )

                User.GotApiSetResponse _ ->
                    ( model, Cmd.none )

                User.GotTranslationFromLocale _ ->
                    let
                        ( newUser, _ ) =
                            User.update userMsg model.user

                        newModel =
                            if model.locale == User.preferredLocale newUser then
                                { model | user = newUser }

                            else
                                { model | user = newUser, locale = User.preferredLocale newUser }
                    in
                    ( newModel, Cmd.none )


view : Model -> Document Msg
view model =
    let
        { title, body } =
            Page.view model
    in
    { title = title, body = List.map (Html.map PageMsg) body }
