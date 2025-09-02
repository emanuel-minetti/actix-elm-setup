module Api.Login exposing (ApiResponseData, post)

import Api
import Effect exposing (Effect)
import Http
import Json.Decode exposing (Decoder, field, map, string)
import Json.Encode


type alias ApiResponseData =
    { token : String }


apiResponseDataDecoder : Decoder ApiResponseData
apiResponseDataDecoder =
    field "Login"
        (map
            (\s -> { token = s })
            (field "session_token" string)
        )


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
