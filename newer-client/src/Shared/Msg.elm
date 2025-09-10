module Shared.Msg exposing (Msg(..))

import Api
import Api.Session.Model
import Http
import I18Next exposing (Translations)
import User exposing (User)


type Msg
    = TranslationsApiResponded (Result Http.Error Translations)
    | SessionApiResponded String (Result Http.Error (Api.ApiResponse Api.Session.Model.SessionApiResponseData))
    | LoginApiResponded User
    | Logout
