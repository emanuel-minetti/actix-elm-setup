module Shared.Model exposing (Model)

import Api
import I18Next exposing (Translations)
import Locale exposing (Locale)


type alias Model =
    { locale : Locale
    , translationsApiData : Api.Data Translations
    }
