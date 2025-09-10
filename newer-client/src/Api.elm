module Api exposing (ApiResponse, ApiResponseData(..), Data(..), apiResponseDecoder, noneResponseDataDecoder, schemeAndHost)

import Http
import Json.Decode exposing (Decoder, field, int, map, map3, string, succeed)


schemeAndHost : String
schemeAndHost =
    "http://localhost:8080/"


type Data value
    = Loading
    | Success value
    | Failure Http.Error


type alias ApiResponse data =
    { expires : Int
    , error : String
    , data : ApiResponseData data
    }


type ApiResponseData data
    = ResponseData data
    | NoneResponseData {}


apiResponseDecoder : Decoder (ApiResponseData data) -> Decoder (ApiResponse data)
apiResponseDecoder apiResponseDataDecoder =
    map3 ApiResponse
        (field "expires_at" int)
        (field "error" string)
        (field "data" apiResponseDataDecoder)


noneResponseDataDecoder : Decoder (ApiResponseData data)
noneResponseDataDecoder =
    field "None"
        (map (\_ -> NoneResponseData {}) (succeed {}))
