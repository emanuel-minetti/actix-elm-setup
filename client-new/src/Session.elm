module Session exposing (Session, init, isLoggedIn, locale, navKey, setLocale, setUser, user)

import Browser.Navigation as Nav
import Locale exposing (Locale)
import User exposing (User)


type Session
    = Session
        { locale : Locale
        , navKey : Nav.Key
        , user : User
        }


init : Locale -> Nav.Key -> User -> Session
init newLocale newNavKey newUser =
    Session { locale = newLocale, navKey = newNavKey, user = newUser }


locale : Session -> Locale
locale session =
    case session of
        Session record ->
            record.locale


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


setUser : User -> Session -> Session
setUser newUser session =
    case session of
        Session record ->
            Session { record | user = newUser }
