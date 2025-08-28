module Api.Translations exposing (..)

import Effect exposing (Effect)
import Http
import I18Next exposing (Translations)


getTranslations : String -> (Result Http.Error Translations -> msg) -> Effect msg
getTranslations lang options =
    Effect.sendCmd
        (Http.get
            { url = "http://localhost:8080/lang/translation." ++ lang ++ ".json"
            , expect = Http.expectJson options I18Next.translationsDecoder
            }
        )
