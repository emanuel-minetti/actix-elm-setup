module Main exposing (main)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (class)


type alias Model =
    {}


initialModel : Model
initialModel =
    {}


view _ =
    { title = "Elm-Intl"
    , body = viewBody
    }


viewBody =
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


main =
    Browser.document
        { init = \() -> ( initialModel, Cmd.none )
        , update = \_ _ -> ( initialModel, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = view
        }
