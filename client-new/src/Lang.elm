module Lang exposing (Lang, fromString, getLangs, toText, toValue)

import I18Next exposing (Translations)
import Translations.Lang as I18n


type Lang
    = De
    | En


getLangs : List Lang
getLangs =
    [ De, En ]


toValue : Lang -> String
toValue lang =
    case lang of
        De ->
            "de"

        En ->
            "en"


toText : Lang -> Translations -> String
toText lang =
    case lang of
        De ->
            I18n.german

        En ->
            I18n.english


fromString : String -> Lang
fromString string =
    case string of
        "de" ->
            De

        "en" ->
            En

        _ ->
            De
