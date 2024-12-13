module Session exposing (Session)

import Browser.Navigation as Nav
import Locale exposing (Locale)
import Route exposing (Route)
import User exposing (User)


type alias Session =
    { locale : Locale
    , route : Route
    , navKey : Nav.Key
    , user : Maybe User
    }
