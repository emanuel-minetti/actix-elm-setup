module Error exposing (..)

import Http
import I18Next exposing (Translations)
import Translations.Error as I18n


type Error
    = HttpError String Http.Error
    | ApiError String String


toString : Translations -> Error -> String
toString t error =
    let
        caller =
            case error of
                HttpError called _ ->
                    called

                ApiError called _ ->
                    called

        message =
            I18n.intro t caller
    in
    message
