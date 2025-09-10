module Api.Login exposing (Model, post)

import Api exposing (ApiResponseData(..))
import Api.Login.Model exposing (LoginApiResponseData)
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (Decoder, Value, andThen, decodeValue, fail, field, keyValuePairs, string)
import Json.Encode


type alias Model =
    LoginApiResponseData


apiResponseDataDecoder : Decoder (ApiResponseData LoginApiResponseData)
apiResponseDataDecoder =
    Dec.value |> andThen apiResponseDecoderHelper


apiResponseDecoderHelper : Value -> Decoder (ApiResponseData LoginApiResponseData)
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
            Api.noneResponseDataDecoder

        _ ->
            fail <| "No such service"


apiLoginResponseDataDecoder : Decoder (ApiResponseData LoginApiResponseData)
apiLoginResponseDataDecoder =
    field "Login"
        (Dec.map
            (\s -> ResponseData (Api.Login.Model.LoginApiResponseData s))
            (field "session_token" string)
        )


post :
    { onResponse : Result Http.Error (Api.ApiResponse LoginApiResponseData) -> msg
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
