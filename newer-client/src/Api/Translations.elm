module Api.Translations exposing (..)

import Http
import I18Next exposing (Translations)


getTranslations : String -> { onResponse : Result Http.Error Translations -> msg } -> Cmd msg
getTranslations lang options =
    Http.get
        { url = "http://localhost:8080/lang/translation." ++ lang ++ ".json"
        , expect = Http.expectJson options.onResponse I18Next.translationsDecoder
        }
