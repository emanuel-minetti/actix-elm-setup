module Api.Translations exposing (..)

import Api
import Effect exposing (Effect)
import Http
import I18Next exposing (Translations)


getTranslations : String -> (Result Http.Error Translations -> msg) -> Effect msg
getTranslations lang options =
    -- TODO use!
    Effect.sendCmd
        (Http.get
            { url = Api.schemeAndHost ++ "lang/translation." ++ lang ++ ".json"
            , expect = Http.expectJson options I18Next.translationsDecoder
            }
        )
