module Api.Session exposing (Model, get)

import Api exposing (ApiResponseData(..))
import Api.Session.Model exposing (SessionApiResponseData)
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (..)


type alias Model =
    SessionApiResponseData


apiResponseDataDecoder : Decoder (ApiResponseData SessionApiResponseData)
apiResponseDataDecoder =
    Dec.value |> andThen apiResponseDecoderHelper


apiResponseDecoderHelper : Value -> Decoder (ApiResponseData SessionApiResponseData)
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
            Api.noneResponseDataDecoder

        _ ->
            fail <| "No such service"


apiSessionResponseDataDecoder : Decoder (ApiResponseData SessionApiResponseData)
apiSessionResponseDataDecoder =
    field "Session"
        (Dec.map2 (\s t -> ResponseData (Api.Session.Model.SessionApiResponseData s t))
            (field "name" string)
            (field "preferred_lang" string)
        )


get : { onResponse : Result Http.Error (Api.ApiResponse SessionApiResponseData) -> msg, token : String } -> Effect msg
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
