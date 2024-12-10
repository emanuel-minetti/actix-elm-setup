module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import I18Next exposing (Delims(..), Translations, translationsDecoder)
import Locale exposing (Locale)
import Translations.Main as I18n
import Url exposing (Url)


type alias Model =
    { locale : Locale
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotTranslation (Result Http.Error Translations)
    | GotTranslationFromInit Locale.Msg
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
        ( locale, localeCmd ) =
            Locale.init flags
    in
    ( Model locale, Cmd.map GotTranslationFromInit localeCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTranslation result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok translation ->
                    let
                        locale =
                            Locale.changeTranslations model.locale translation
                    in
                    ( { model | locale = locale }, Cmd.none )

        SwitchLanguage newValue ->
            let
                locale =
                    Locale.changeLang model.locale newValue
            in
            ( { model | locale = locale }, loadTranslation locale )

        GotTranslationFromInit localeCmd ->
            let
                ( locale, _ ) =
                    Locale.update localeCmd model.locale
            in
            ( { model | locale = locale }, Cmd.none )

        _ ->
            ( model, Cmd.none )


loadTranslation : Locale -> Cmd Msg
loadTranslation locale =
    Http.request
        { method = "GET"
        , url = "http://127.0.0.1:8080/lang/translation." ++ Locale.toValue locale ++ ".json"
        , headers = [ Http.header "Accept" "application/json" ]
        , body = Http.emptyBody
        , expect = Http.expectJson GotTranslation translationsDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


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
                , select [ onInput SwitchLanguage ] <| viewLangOptions model
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
                    [ ul [ class "list-unstyled" ]
                        [ li [] [ button [] [ text <| I18n.footerPrivacy model.locale.t ] ]
                        , li [] [ button [] [ text <| I18n.footerImprint model.locale.t ] ]
                        ]
                    ]
                , div [ class "col" ]
                    --todo get from config
                    [ span [ class "float-end" ] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]


viewLangOptions : Model -> List (Html Msg)
viewLangOptions model =
    let
        localeToText locale =
            Locale.toText locale

        isSelected locale =
            locale.lang == model.locale.lang

        langToOption locale =
            option [ value <| Locale.toValue locale, selected <| isSelected locale ] [ text <| localeToText locale model.locale.t ]
    in
    List.map langToOption Locale.getLocaleOptions
