module Api.Translations exposing (..)

import Effect exposing (Effect)
import Http
import I18Next exposing (Translations)
import Shared.Msg exposing (Msg)


getTranslations : String -> (Result Http.Error Translations -> Msg) -> Effect Msg
getTranslations lang options =
    Effect.sendCmd
        (Http.get
            { url = "http://localhost:8080/lang/translation." ++ lang ++ ".json"
            , expect = Http.expectJson options I18Next.translationsDecoder
            }
        )
