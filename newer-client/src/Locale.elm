module Locale exposing
    ( Language
    , Locale
    , init
    , languages
    , toLanguageString
    , toLanguageStringValue
    , toLanguageValue
    )

import I18Next exposing (Translations)
import Translations.Lang as I18n


type Language
    = De
    | En


languages : List Language
languages =
    [ De, En ]


type alias Locale =
    { lang : Language
    , t : I18Next.Translations
    }


init : String -> Locale
init lang =
    let
        language =
            case lang of
                "de" ->
                    De

                "en" ->
                    En

                _ ->
                    De
    in
    { lang = language
    , t = I18Next.initialTranslations
    }


toLanguageString : Translations -> Language -> String
toLanguageString t lang =
    case lang of
        De ->
            I18n.german t

        En ->
            I18n.english t


toLanguageStringValue : Language -> String
toLanguageStringValue lang =
    case lang of
        De ->
            "de"

        En ->
            "en"


toLanguageValue : Locale -> String
toLanguageValue locale =
    case locale.lang of
        De ->
            "De"

        En ->
            "En"
