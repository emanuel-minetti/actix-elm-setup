module ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)

import Json.Decode as Dec exposing (..)


type alias ApiResponse =
    { expires : Int
    , error : String
    , data : ApiResponseData
    }


apiResponseDecoder : Decoder ApiResponse
apiResponseDecoder =
    map3 ApiResponse
        (field "expires_at" int)
        (field "error" string)
        (field "data" apiResponseDataDecoder)


type ApiResponseData
    = LoginResponseData { token : String }
    | SessionResponseData
        { name : String
        , lang : String
        }
    | NoneResponseData {}


apiResponseDataDecoder : Decoder ApiResponseData
apiResponseDataDecoder =
    Dec.value |> andThen apiResponseDecoderHelper


apiResponseDecoderHelper : Value -> Decoder ApiResponseData
apiResponseDecoderHelper val =
    let
        apiListResult =
            decodeValue (keyValuePairs value) val

        api =
            case apiListResult of
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
        "Login" ->
            loginResponseDataDecoder

        "Session" ->
            sessionResponseDataDecoder

        "None" ->
            noneResponseDataDecoder

        _ ->
            fail <| "No such service"


loginResponseDataDecoder : Decoder ApiResponseData
loginResponseDataDecoder =
    field "Login"
        (Dec.map
            (\s -> LoginResponseData { token = s })
            (field "session_token" string)
        )


sessionResponseDataDecoder : Decoder ApiResponseData
sessionResponseDataDecoder =
    field "Session"
        (map2
            (\n l -> SessionResponseData { name = n, lang = l })
            (field "name" string)
            (field "preferred_lang" string)
        )


noneResponseDataDecoder : Decoder ApiResponseData
noneResponseDataDecoder =
    field "None"
        (Dec.map (\_ -> NoneResponseData {}) (succeed {}))
