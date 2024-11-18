module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Url exposing (Url)


view : Model -> Document Msg
view _ =
    { title = "Actix Elm Setup"
    , body =
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
    }


type alias Model =
    {}


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest


main : Program (Array String) Model Msg
main =
    Browser.application
        { init = \_ _ _ -> ( Model, Cmd.none )
        , update = \_ _ -> ( Model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }
