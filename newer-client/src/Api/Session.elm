module Api.Session exposing (Model, get)

import Api
import Api.Session.Model exposing (SessionApiResponseData)
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (..)


type alias Model =
    SessionApiResponseData


apiSessionResponseDataDecoder : Decoder (Api.ApiResponseData SessionApiResponseData)
apiSessionResponseDataDecoder =
    field "Session"
        (Dec.map2 (\s t -> Api.ResponseData (Api.Session.Model.SessionApiResponseData s t))
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

        decoder =
            apiSessionResponseDataDecoder
                |> Api.apiResponseDataDecoder "Session"
                |> Api.apiResponseDecoder

        cmd =
            Http.request
                { method = "GET"
                , headers = [ header ]
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson options.onResponse decoder
                , timeout = Nothing
                , tracker = Nothing
                }
    in
    Effect.sendCmd cmd
