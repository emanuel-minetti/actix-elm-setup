module Api exposing (ApiResponse, Data(..), apiResponseDecoder, schemeAndHost)

import Http
import Json.Decode exposing (Decoder, field, int, map3, string)


schemeAndHost : String
schemeAndHost =
    "http://localhost:8080/"


type Data value
    = Loading
    | Success value
    | Failure Http.Error


type alias ApiResponse apiResponseData =
    { expires : Int
    , error : String
    , data : apiResponseData
    }


apiResponseDecoder : Decoder apiResponseData -> Decoder (ApiResponse apiResponseData)
apiResponseDecoder apiResponseDataDecoder =
    map3 ApiResponse
        (field "expires_at" int)
        (field "error" string)
        (field "data" apiResponseDataDecoder)
