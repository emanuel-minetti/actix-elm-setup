module Api.Session.Model exposing (ApiResponseData(..), SessionApiResponseData)


type ApiResponseData
    = SessionResponseData SessionApiResponseData
    | NoneResponseData {}


type alias SessionApiResponseData =
    { name : String
    , lang : String
    }
