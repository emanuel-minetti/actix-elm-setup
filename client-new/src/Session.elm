module Session exposing (Session, isLoggedIn)

import Browser.Navigation as Nav
import Locale exposing (Locale)
import Route exposing (Route)
import User exposing (User)


type alias Session =
    { locale : Locale
    , route : Route
    , navKey : Nav.Key
    , user : User
    }


isLoggedIn : Session -> Bool
isLoggedIn session =
    (session.user
        |> User.name
        |> String.length
    )
        > 0
