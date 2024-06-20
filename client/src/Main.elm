module Main exposing (main)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, selected, src, width)
import Http
import I18n exposing (I18n)


type alias Model =
    { user : Maybe String
    , i18n : I18n
    }


type Msg
    = GotTranslations (Result Http.Error (I18n -> I18n))


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


view : Model -> Document msg
view model =
    { title = "Actix Elm Setup"
    , body = viewBody model
    }


viewBody : Model -> List (Html msg)
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


viewHeader : Model -> Html msg
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
                , select []
                    [ option [] [ text (I18n.german model.i18n) ]
                    , option [ selected True ] [ text (I18n.english model.i18n) ]
                    ]
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


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
