module User exposing (User)


type alias User =
    { token : String
    , expires : Int
    , name : String
    , preferredLang : String
    }
