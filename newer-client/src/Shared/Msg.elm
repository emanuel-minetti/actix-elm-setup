module Shared.Msg exposing (Msg(..))

import Http
import I18Next exposing (Translations)
import User exposing (User)


type Msg
    = NoOp
    | TranslationsApiResponded (Result Http.Error Translations)
    | LoginApiResponded User
    | Logout
