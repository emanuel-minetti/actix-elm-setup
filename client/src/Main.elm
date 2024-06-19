module Main exposing (main)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, src, width)


type alias Model =
    { user : Maybe String }


initialModel : Model
initialModel =
    { user = Just "Emu" }


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
            [ div [ class "container" ]
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
                ]
            ]
        ]


viewLoginText : Model -> Html msg
viewLoginText model =
    case model.user of
        Nothing ->
            text "Sie sind nicht angemeldet"

        Just userName ->
            text ("Sie sind angemdet als: " ++ userName)


main : Program () Model msg
main =
    Browser.document
        { init = \() -> ( initialModel, Cmd.none )
        , update = \_ _ -> ( initialModel, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = view
        }
