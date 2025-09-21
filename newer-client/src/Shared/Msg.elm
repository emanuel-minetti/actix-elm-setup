module Shared.Msg exposing (Msg(..))

import Api
import Api.Session.Model
import Http
import I18Next exposing (Translations)
import Route.Path exposing (Path)
import Time
import User exposing (User)


type Msg
    = TranslationsApiResponded (Result Http.Error Translations)
    | RestoreSessionApiResponded String (Result Http.Error (Api.ApiResponse Api.Session.Model.SessionApiResponseData))
    | LoginSucceeded User Path
    | Logout
    | ChangeLocale String
    | ChangeLocaleResponded (Result Http.Error (Api.ApiResponse Api.Session.Model.SessionApiResponseData))
    | GotTime Time.Posix
    | ClearErrors
    | RenewSession String
