module Api.Session.Model exposing (SessionApiResponseData(..), lang, name)


type SessionApiResponseData
    = Data
        { name : String
        , lang : String
        }


name : SessionApiResponseData -> String
name (Data data) =
    data.name


lang : SessionApiResponseData -> String
lang (Data data) =
    data.lang
