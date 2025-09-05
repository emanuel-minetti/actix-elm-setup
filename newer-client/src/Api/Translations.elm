module Api.Translations exposing (..)

import Api
import Effect exposing (Effect)
import Http
import I18Next exposing (Translations)


getTranslations : { lang : String, onResponse : Result Http.Error Translations -> msg } -> Effect msg
getTranslations options =
    -- TODO use!
    Effect.sendCmd
        (Http.get
            { url = Api.schemeAndHost ++ "lang/translation." ++ options.lang ++ ".json"
            , expect = Http.expectJson options.onResponse I18Next.translationsDecoder
            }
        )
