module Locale exposing (Locale, init, toLanguageString)

import I18Next
import Translations.Lang as I18n


type Language
    = De
    | En


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


toLanguageString : Locale -> String
toLanguageString locale =
    case locale.lang of
        De ->
            I18n.german locale.t

        En ->
            I18n.english locale.t
