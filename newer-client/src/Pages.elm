module Pages exposing (Page(..), toPath, toText)

import I18Next exposing (Translations)
import Translations.Route as I18n


type Page
    = Imprint
    | Privacy


toText : Page -> Translations -> String
toText page t =
    case page of
        Imprint ->
            I18n.imprint t

        Privacy ->
            I18n.privacy t


toPath : Page -> String
toPath page =
    case page of
        Imprint ->
            "imprint"

        Privacy ->
            "privacy"
