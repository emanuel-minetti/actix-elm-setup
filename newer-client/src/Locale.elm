module Locale exposing (..)

import Api
import I18Next


type alias Locale =
    { lang : String
    , t : Api.Data I18Next.Translations
    }


init : String -> Locale
init lang =
    { lang = lang
    , t = Api.Loading
    }
