module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Locale exposing (Locale)
import Page
import Route exposing (Route(..))
import Session exposing (Session)
import Translations.Main as I18n
import Url exposing (Url)


type alias Model =
    Session


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslationFromLocale Locale.Msg
    | GotTranslationFromPage Page.Msg
    | SwitchLanguage Page.Msg


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

        SwitchLanguage pageCmd ->
            let
                ( session, newPageCmd ) =
                    Page.update pageCmd model
            in
            ( { model | locale = session.locale }, Cmd.map GotTranslationFromPage newPageCmd )


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = [ Html.map SwitchLanguage <| Page.viewHeader model, viewContent model, viewFooter model ]
    }


viewContent : Model -> Html Msg
viewContent model =
    case model.route of
        Home ->
            div [ class "container" ]
                [ text "Das ist Home"
                , br [] []
                , text <| I18n.yourPreferredLang model.locale.t <| Locale.toValue model.locale
                ]

        NotFound ->
            div [ class "container" ]
                [ text "Das ist NotFound"
                , br [] []
                , text <| I18n.yourPreferredLang model.locale.t <| Locale.toValue model.locale
                ]

        Privacy ->
            div [ class "container" ]
                [ text "Das ist Privacy"
                , br [] []
                , text <| I18n.yourPreferredLang model.locale.t <| Locale.toValue model.locale
                ]

        Imprint ->
            div [ class "container" ]
                [ text "Das ist Imprint"
                , br [] []
                , text <| I18n.yourPreferredLang model.locale.t <| Locale.toValue model.locale
                ]


viewFooter : Model -> Html Msg
viewFooter model =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] <| viewFooterLinks model.locale ]
                , div [ class "col" ]
                    --todo get from config
                    [ span [ class "float-end" ] [ text "Version: 0.0.0" ] ]
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
