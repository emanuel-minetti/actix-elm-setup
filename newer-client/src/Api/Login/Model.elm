module Api.Login.Model exposing (LoginApiResponseData(..), token)


type LoginApiResponseData
    = Data { token : String }


token : LoginApiResponseData -> String
token (Data data) =
    data.token
