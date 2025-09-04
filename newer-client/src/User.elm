module User exposing (User)


type alias User =
    { token : String
    , expires : Int
    , name : String
    , preferredLang : String
    }


init : String -> Int -> String -> String -> User
init token expires name lang =
    { token = token, expires = expires, name = name, preferredLang = lang }
