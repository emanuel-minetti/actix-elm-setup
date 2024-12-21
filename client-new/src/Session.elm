module Session exposing (Session, init, isLoggedIn, locale, navKey, route, setLocale, setRoute, setUser, user)

import Browser.Navigation as Nav
import Locale exposing (Locale)
import Route exposing (Route)
import User exposing (User)


type Session
    = Session
        { locale : Locale
        , route : Route
        , navKey : Nav.Key
        , user : User
        }


init : Locale -> Route -> Nav.Key -> User -> Session
init newLocale newRoute newNavKey newUser =
    Session { locale = newLocale, route = newRoute, navKey = newNavKey, user = newUser }


locale : Session -> Locale
locale session =
    case session of
        Session record ->
            record.locale


route : Session -> Route
route session =
    case session of
        Session record ->
            record.route


navKey : Session -> Nav.Key
navKey session =
    case session of
        Session record ->
            record.navKey


user : Session -> User
user session =
    case session of
        Session record ->
            record.user


isLoggedIn : Session -> Bool
isLoggedIn session =
    (session
        |> user
        |> User.name
        |> String.length
    )
        > 0


setLocale : Locale -> Session -> Session
setLocale newLocale session =
    case session of
        Session record ->
            Session { record | locale = newLocale }


setRoute : Route -> Session -> Session
setRoute newRoute session =
    case session of
        Session record ->
            Session { record | route = newRoute }


setUser : User -> Session -> Session
setUser newUser session =
    case session of
        Session record ->
            Session { record | user = newUser }
