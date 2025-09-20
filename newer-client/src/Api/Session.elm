module Api.Session exposing (Model, get, post)

import Api
import Api.Session.Model exposing (SessionApiResponseData)
import Effect exposing (Effect)
import Http
import Json.Decode as Dec exposing (..)
import Json.Encode


type alias Model =
    SessionApiResponseData


apiSessionResponseDataDecoder : Decoder (Api.ApiResponseData SessionApiResponseData)
apiSessionResponseDataDecoder =
    field "Session"
        (Dec.map2 (\s t -> Api.ResponseData (Api.Session.Model.Data { name = s, lang = t }))
            (field "name" string)
            (field "preferred_lang" string)
        )


get :
    { onResponse : Result Http.Error (Api.ApiResponse SessionApiResponseData) -> msg
    , token : String
    }
    -> Effect msg
get options =
    request { method = "GET", token = options.token, body = Http.emptyBody, onResponse = options.onResponse }


post :
    { token : String
    , lang : String
    , onResponse : Result Http.Error (Api.ApiResponse SessionApiResponseData) -> msg
    }
    -> Effect msg
post options =
    let
        body =
            [ ( "preferred_lang", Json.Encode.string options.lang ) ]
                |> Json.Encode.object
                |> Http.jsonBody
    in
    request { method = "POST", token = options.token, body = body, onResponse = options.onResponse }


request :
    { method : String
    , token : String
    , body : Http.Body
    , onResponse : Result Http.Error (Api.ApiResponse SessionApiResponseData) -> msg
    }
    -> Effect msg
request options =
    let
        url =
            Api.schemeAndHost ++ "api/session"

        header =
            Http.header "Authorization" <| "Bearer " ++ options.token

        decoder =
            "Session"
                |> Api.apiResponseDataDecoder apiSessionResponseDataDecoder
                |> Api.apiResponseDecoder
    in
    { method = options.method
    , url = url
    , headers = [ header ]
    , body = options.body
    , expect = Http.expectJson options.onResponse decoder
    , timeout = Nothing
    , tracker = Nothing
    }
        |> Http.request
        |> Effect.sendCmd
