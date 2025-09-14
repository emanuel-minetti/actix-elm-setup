module Shared.Model exposing (Model)

import Api
import Error exposing (Error)
import I18Next exposing (Translations)
import Locale exposing (Locale)
import User exposing (User)


type alias Model =
    { translationsApiData : Api.Data Translations
    , isRestoringSession : Bool
    , locale : Locale
    , user : Maybe User
    , globalErrors : List Error
    }
