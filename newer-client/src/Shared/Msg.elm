module Shared.Msg exposing (Msg(..))

import Http
import I18Next exposing (Translations)


type Msg
    = NoOp
    | TranslationsApiResponded (Result Http.Error Translations)
    | LoginApiResponded { token : String }
    | Logout
