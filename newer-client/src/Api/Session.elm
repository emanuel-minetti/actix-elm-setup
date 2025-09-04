module Api.Session exposing (ApiResponseData(..), get)

import Api
import Api.Session.Model
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (..)


type ApiResponseData
    = SessionResponseData Api.Session.Model.ApiResponseData
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
        "Session" ->
            apiSessionResponseDataDecoder

        "None" ->
            noneResponseDataDecoder

        _ ->
            fail <| "No such service"


noneResponseDataDecoder : Decoder ApiResponseData
noneResponseDataDecoder =
    field "None"
        (Dec.map (\_ -> NoneResponseData {}) (succeed {}))


apiSessionResponseDataDecoder : Decoder ApiResponseData
apiSessionResponseDataDecoder =
    field "Session"
        (Dec.map2 (\s t -> SessionResponseData { name = s, lang = t })
            (field "name" string)
            (field "preferred_lang" string)
        )


get : { onResponse : Result Http.Error (Api.ApiResponse ApiResponseData) -> msg, token : String } -> Effect msg
get options =
    let
        url =
            Api.schemeAndHost ++ "api/session"

        header =
            Http.header "Authorization" <| "Bearer " ++ options.token

        cmd =
            Http.request
                { method = "GET"
                , headers = [ header ]
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson options.onResponse (Api.apiResponseDecoder apiResponseDataDecoder)
                , timeout = Nothing
                , tracker = Nothing
                }
    in
    Effect.sendCmd cmd
