module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Locale exposing (Locale)
import Route exposing (Route)
import Translations.Main as I18n
import Url exposing (Url)


type alias Model =
    { locale : Locale
    , route : Route
    , navKey : Nav.Key
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslation Locale.Msg
    | SwitchLanguage String


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
            [ Cmd.map GotTranslation localeCmd ]
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

        SwitchLanguage newValue ->
            let
                locale =
                    Locale.changeLang model.locale newValue
            in
            ( { model | locale = locale }, Cmd.map GotTranslation <| Locale.loadTranslation locale )

        GotTranslation localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd model.locale
            in
            ( { model | locale = locale }, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = [ viewHeader model, viewContent model, viewFooter model ]
    }


viewHeader : Model -> Html Msg
viewHeader model =
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
                , span [ class "navbar-text" ] [ text <| I18n.loggedInText model.locale.t ]
                , select [ onInput SwitchLanguage ] <| Locale.viewLangOptions model.locale
                ]
            ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    div [ class "container" ]
        [ text <| I18n.yourPreferredLang model.locale.t <| Locale.toValue model.locale ]


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
