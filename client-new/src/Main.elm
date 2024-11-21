module Main exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url exposing (Url)


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
            [ text ("Your preferred Language is: " ++ model.lang) ]
        ]
    }


type alias Model =
    { lang : String
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest


main : Program (Array String) Model Msg
main =
    Browser.application
        { init = init
        , update = \_ model -> ( model, Cmd.none )
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
            String.slice 0 2 <| Maybe.withDefault defaultLang <| Array.get 0 flags

        lang =
            if langFromBrowser == "en" || langFromBrowser == "de" then
                langFromBrowser

            else
                defaultLang

        initialModel =
            { lang = lang
            }
    in
    ( initialModel, Cmd.none )
