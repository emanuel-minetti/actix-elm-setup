module Api.Login exposing (ApiResponseData(..), post)

import Api
import Api.Login.Model
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (Decoder, Value, andThen, decodeValue, fail, field, keyValuePairs, map, string, succeed)
import Json.Encode


type ApiResponseData
    = LoginResponseData Api.Login.Model.ApiResponseData
    | NoneResponseData {}


apiResponseDataDecoder : Decoder ApiResponseData
apiResponseDataDecoder =
    Dec.value |> andThen apiResponseDecoderHelper


apiResponseDecoderHelper : Value -> Decoder ApiResponseData
apiResponseDecoderHelper value =
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
        "Login" ->
            apiLoginResponseDataDecoder

        "None" ->
            noneResponseDataDecoder

        _ ->
            fail <| "No such service"


apiLoginResponseDataDecoder : Decoder ApiResponseData
apiLoginResponseDataDecoder =
    field "Login"
        (Dec.map
            (\s -> LoginResponseData { token = s })
            (field "session_token" string)
        )


noneResponseDataDecoder : Decoder ApiResponseData
noneResponseDataDecoder =
    field "None"
        (Dec.map (\_ -> NoneResponseData {}) (succeed {}))


post :
    { onResponse : Result Http.Error (Api.ApiResponse ApiResponseData) -> msg
    , user : String
    , password : String
    }
    -> Effect msg
post options =
    let
        body =
            Json.Encode.object
                [ ( "account", Json.Encode.string options.user )
                , ( "pw", Json.Encode.string options.password )
                ]

        cmd =
            Http.post
                { url = Api.schemeAndHost ++ "api/login"
                , body = Http.jsonBody body
                , expect = Http.expectJson options.onResponse (Api.apiResponseDecoder apiResponseDataDecoder)
                }
    in
    Effect.sendCmd cmd
