module Api exposing
    ( ApiResponse
    , ApiResponseData(..)
    , Data(..)
    , apiResponseDataDecoder
    , apiResponseDecoder
    , schemeAndHost
    )

import Http
import Json.Decode as Dec
    exposing
        ( Decoder
        , Value
        , andThen
        , decodeValue
        , fail
        , field
        , int
        , keyValuePairs
        , map
        , map3
        , string
        , succeed
        , value
        )


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
apiResponseDecoder responseDataDecoder =
    map3 ApiResponse
        (field "expires_at" int)
        (field "error" string)
        (field "data" responseDataDecoder)


apiResponseDataDecoder : Decoder (ApiResponseData data) -> String -> Decoder (ApiResponseData data)
apiResponseDataDecoder dataDecoder jsonFieldName =
    value |> andThen (apiResponseDecoderHelper dataDecoder jsonFieldName)


apiResponseDecoderHelper : Decoder (ApiResponseData data) -> String -> Value -> Decoder (ApiResponseData data)
apiResponseDecoderHelper dataDecoder jsonFieldName value =
    let
        pairs =
            decodeValue (keyValuePairs Dec.value) value

        api =
            case pairs of
                Err _ ->
                    "None"

                Ok list ->
                    case List.head list of
                        Just ( key, _ ) ->
                            key

                        Nothing ->
                            "None"
    in
    case api of
        "None" ->
            noneResponseDataDecoder

        _ ->
            if api == jsonFieldName then
                dataDecoder

            else
                fail <| "No such Client service"


noneResponseDataDecoder : Decoder (ApiResponseData data)
noneResponseDataDecoder =
    field "None"
        (map (\_ -> NoneResponseData {}) (succeed {}))
