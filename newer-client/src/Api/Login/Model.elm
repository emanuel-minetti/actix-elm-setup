module Api.Login.Model exposing (ApiResponseData(..), LoginApiResponseData)


type ApiResponseData
    = LoginResponseData LoginApiResponseData
    | NoneResponseData {}


type alias LoginApiResponseData =
    { token : String }
