module Api.Translations exposing (get)

import Api
import Effect exposing (Effect)
import Http
import I18Next exposing (Translations)


get : { lang : String, onResponse : Result Http.Error Translations -> msg } -> Effect msg
get options =
    Effect.sendCmd
        (Http.get
            { url = Api.schemeAndHost ++ "lang/translation." ++ options.lang ++ ".json"
            , expect = Http.expectJson options.onResponse I18Next.translationsDecoder
            }
        )
