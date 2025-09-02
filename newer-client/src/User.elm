module User exposing (..)


type alias User =
    { token : String, expires : Int }


init : String -> Int -> User
init token expires =
    { token = token, expires = expires }
