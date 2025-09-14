module Error exposing (..)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Http
import I18Next exposing (Translations)
import Translations.Error as I18n


type Error
    = HttpError String Http.Error
    | ApiError String String


toView : Translations -> Error -> Html msg
toView t error =
    let
        intro =
            t
                |> I18n.intro
                |> text

        errorMessage =
            p [ class "ms-5" ] [ text "Hallo" ]

        message =
            div [] [ intro, errorMessage ]
    in
    message
