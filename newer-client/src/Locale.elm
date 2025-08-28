module Locale exposing (Locale, init)

import I18Next


type alias Locale =
    { lang : String
    , t : I18Next.Translations
    }


init : String -> Locale
init lang =
    { lang = lang
    , t = I18Next.initialTranslations
    }
