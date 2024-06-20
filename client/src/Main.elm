module Main exposing (main)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, selected, src, value, width)
import Html.Events exposing (onInput)
import Http
import I18n exposing (I18n, Language(..))


type alias Model =
    { user : Maybe String
    , i18n : I18n
    }


type Msg
    = GotTranslations (Result Http.Error (I18n -> I18n))
    | SwitchLanguage String


init : () -> ( Model, Cmd Msg )
init _ =
    let
        i18n =
            I18n.init { lang = I18n.De, path = "lang" }
    in
    ( { user = Just "Emu"
      , i18n = i18n
      }
    , I18n.loadHeader GotTranslations i18n
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTranslations result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok updateI18n ->
                    let
                        newI18n =
                            updateI18n model.i18n
                    in
                    ( { model | i18n = newI18n }, Cmd.none )

        SwitchLanguage _ ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = viewBody model
    }


viewBody : Model -> List (Html Msg)
viewBody model =
    [ viewHeader model
    , div []
        [ h1 [] [ text "Welcome to Emu's Test!" ]
        , p []
            [ text "Emus Test nanu Inc. (stock symbol "
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
                , span [ class "navbar-text" ] [ viewLoginText model ]
                , select [ onInput SwitchLanguage ] (viewSelectOptions model)
                ]
            ]
        ]


viewLoginText : Model -> Html msg
viewLoginText model =
    case model.user of
        Nothing ->
            text (I18n.notLoggedIn model.i18n)

        Just userName ->
            text (I18n.loggedInAs model.i18n ++ userName)


viewSelectOptions : Model -> List (Html Msg)
viewSelectOptions model =
    let
        langToFunc : I18n.Language -> (I18n -> String)
        langToFunc lang =
            case lang of
                En ->
                    I18n.en

                De ->
                    I18n.de

        langToOption : I18n.Language -> Html Msg
        langToOption lang =
            option
                [ value (I18n.languageToString lang)
                , selected (lang == I18n.currentLanguage model.i18n)
                ]
                [ text (langToFunc lang model.i18n) ]
    in
    List.map langToOption I18n.languages


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
