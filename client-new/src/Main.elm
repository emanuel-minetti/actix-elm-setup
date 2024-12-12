module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Locale exposing (Locale)
import Page
import Route exposing (Route(..))
import Session exposing (Session)
import Url exposing (Url)


type alias Model =
    Session


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslationFromLocale Locale.Msg
    | GotTranslationFromPage Page.Msg
    | PageMsg Page.Msg


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
        ( locale, localeCmd ) =
            Locale.init flags

        model =
            { locale = locale
            , route = Route.parseUrl url
            , navKey = navKey
            }

        cmds =
            [ Cmd.map GotTranslationFromLocale localeCmd ]
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
                Page.SwitchLanguage _ ->
                    let
                        ( session, newPageCmd ) =
                            Page.update pageMsg model
                    in
                    ( { model | locale = session.locale }, Cmd.map GotTranslationFromPage newPageCmd )

                Page.GotTranslation _ ->
                    ( model, Cmd.none )


view : Model -> Document Msg
view model =
    let
        { title, body } =
            Page.view model
    in
    { title = title, body = List.map (Html.map PageMsg) body }
