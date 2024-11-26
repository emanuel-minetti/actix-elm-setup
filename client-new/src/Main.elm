module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import I18Next exposing (Delims(..), Translations, initialTranslations, translationsDecoder)
import Translations.Main as I18n
import Url exposing (Url)


type alias Model =
    { lang : String
    , t : Translations
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslation (Result Http.Error Translations)
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
init flags _ _ =
    let
        defaultLang =
            "en"

        langFromBrowser =
            Array.get 0 flags
                |> Maybe.withDefault defaultLang
                |> String.slice 0 2

        lang =
            if langFromBrowser == "en" || langFromBrowser == "de" then
                langFromBrowser

            else
                defaultLang

        initialModel =
            { lang = lang
            , t = initialTranslations
            }
    in
    ( initialModel, loadTranslation lang )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTranslation result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok translation ->
                    ( { model | t = translation }, Cmd.none )

        SwitchLanguage newValue ->
            let
                _ =
                    Debug.log newValue ""
            in
            ( { model | lang = newValue }, loadTranslation newValue )

        _ ->
            ( model, Cmd.none )


loadTranslation : String -> Cmd Msg
loadTranslation lang =
    Http.request
        { method = "GET"
        , url = "http://127.0.0.1:8080/lang/main." ++ lang ++ ".json"
        , headers = [ Http.header "Accept" "application/json" ]
        , body = Http.emptyBody
        , expect = Http.expectJson GotTranslation translationsDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body =
        [ div []
            [ div [ class "jumbotron" ]
                [ h1 [] [ text "Welcome to Dunder Mifflin!" ]
                , p []
                    [ text "Dunder Mifflin Inc. (stock symbol "
                    , strong [] [ text "DMI" ]
                    , text <|
                        """
                                         ) is a micro-cap regional paper and office
                                         supply distributor with an emphasis on servicing
                                         small-business clients.
                                         """
                    ]
                ]
            ]
        , div [ class "container" ]
            [ text <| I18n.yourPreferredLang model.t model.lang
            , select [ class "form-select", onInput SwitchLanguage ]
                [ option [ value "de" ] [ text "de" ]
                , option [ value "en" ] [ text "en" ]
                ]
            ]
        ]
    }
