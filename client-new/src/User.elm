module User exposing (User, get)

import Locale exposing (Lang)


type alias User =
    { name : String
    , preferredLang : Lang
    , token : String
    , sessionExpiresAt : Int
    }


get : String -> User
get token =
    { name = ""
    , preferredLang = Locale.De
    , token = token
    , sessionExpiresAt = 0
    }
