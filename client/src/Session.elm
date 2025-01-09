module Session exposing (Session, addMessage, currentTime, init, isLoggedIn, locale, messages, navKey, removeSeenMessages, setCurrentTime, setLocale, setUser, user)

import Array exposing (Array)
import Browser.Navigation as Nav
import Locale exposing (Locale)
import Message exposing (Message)
import User exposing (User)


type Session
    = Session
        { locale : Locale
        , navKey : Nav.Key
        , user : User
        , messages : Array Message
        , currentTime : Int
        }


init : Locale -> Nav.Key -> User -> Session
init newLocale newNavKey newUser =
    Session
        { locale = newLocale
        , navKey = newNavKey
        , user = newUser
        , messages = Array.empty
        , currentTime = 0
        }


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


messages : Session -> Array Message
messages session =
    case session of
        Session record ->
            record.messages


currentTime : Session -> Int
currentTime session =
    case session of
        Session record ->
            record.currentTime


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


setCurrentTime : Int -> Session -> Session
setCurrentTime timestamp session =
    case session of
        Session record ->
            Session { record | currentTime = timestamp }


addMessage : Message -> Session -> Session
addMessage message session =
    let
        newMessages =
            Array.push message <| messages session
    in
    case session of
        Session record ->
            Session { record | messages = newMessages }


removeSeenMessages : Array Int -> Session -> Session
removeSeenMessages ints session =
    let
        newSession =
            doRemoveSeenMessages session

        newerSession =
            markSeen ints newSession
    in
    newerSession


doRemoveSeenMessages : Session -> Session
doRemoveSeenMessages session =
    let
        newMessages =
            Array.filter (\m -> not (Message.seen m)) (messages session)
    in
    case session of
        Session record ->
            Session { record | messages = newMessages }


markSeen : Array Int -> Session -> Session
markSeen ints session =
    let
        markMessage int message =
            if List.member int <| Array.toList ints then
                Message.setSeen message

            else
                message

        newMessages =
            Array.indexedMap markMessage <| messages session
    in
    case session of
        Session record ->
            Session { record | messages = newMessages }
