module Session exposing (Session, addMessage, init, isLoggedIn, locale, messages, navKey, resetMessages, setLocale, setUser, user)

import Browser.Navigation as Nav
import Locale exposing (Locale)
import Message exposing (Message)
import User exposing (User)


type Session
    = Session
        { locale : Locale
        , navKey : Nav.Key
        , user : User
        , messages : List Message
        }


init : Locale -> Nav.Key -> User -> Session
init newLocale newNavKey newUser =
    Session { locale = newLocale, navKey = newNavKey, user = newUser, messages = [] }


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


messages : Session -> List Message
messages session =
    case session of
        Session record ->
            record.messages


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


addMessage : Message -> Session -> Session
addMessage message session =
    let
        newMessages =
            message :: messages session
    in
    case session of
        Session record ->
            Session { record | messages = newMessages }


resetMessages : Session -> Session
resetMessages session =
    case session of
        Session record ->
            Session { record | messages = [] }
