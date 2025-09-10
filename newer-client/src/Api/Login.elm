module Api.Login exposing (Model, post)

import Api
import Api.Login.Model exposing (LoginApiResponseData)
import Effect exposing (Effect)
import Http
import Json.Decode exposing (Decoder, Value, field, map, string)
import Json.Encode


type alias Model =
    LoginApiResponseData


apiLoginResponseDataDecoder : Decoder (Api.ApiResponseData LoginApiResponseData)
apiLoginResponseDataDecoder =
    field "Login"
        (map
            (\s -> Api.ResponseData (Api.Login.Model.LoginApiResponseData s))
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

        decoder =
            apiLoginResponseDataDecoder
                |> Api.apiResponseDataDecoder "Login"
                |> Api.apiResponseDecoder

        cmd =
            Http.post
                { url = Api.schemeAndHost ++ "api/login"
                , body = Http.jsonBody body
                , expect = Http.expectJson options.onResponse decoder
                }
    in
    Effect.sendCmd cmd
