module User exposing (Msg(..), User, fromTokenAndLocale, init, loadSession, name, preferredLocale, setSession, setToken, token, update)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Http
import Locale exposing (Locale)
import ServerRequest


type User
    = User
        { name : String
        , preferredLocale : Locale
        , token : String
        , sessionExpiresAt : Int
        }



--GETTERS


name : User -> String
name user =
    case user of
        User record ->
            record.name


preferredLocale : User -> Locale
preferredLocale user =
    case user of
        User record ->
            record.preferredLocale


token : User -> String
token user =
    case user of
        User record ->
            record.token



--CONSTRUCTORS AND SETTERS


fromTokenAndLocale : String -> Locale -> User
fromTokenAndLocale newToken locale =
    User { name = "", preferredLocale = locale, token = newToken, sessionExpiresAt = 0 }


setToken : String -> User -> User
setToken newToken user =
    case user of
        User record ->
            User { record | token = newToken }


setPreferredLocale : Locale -> User -> User
setPreferredLocale locale user =
    case user of
        User record ->
            User { record | preferredLocale = locale }


setExpiresAt : Int -> User -> User
setExpiresAt expiresAt user =
    case user of
        User record ->
            User { record | sessionExpiresAt = expiresAt }


type Msg
    = GotApiLoadResponse (Result Http.Error ApiResponse)
    | GotApiSetResponse (Result Http.Error ApiResponse)
    | GotTranslationFromLocale Locale.Msg


init : String -> Locale -> ( User, Cmd Msg )
init newToken locale =
    let
        sessionMsg =
            if String.length newToken > 0 then
                loadSession newToken

            else
                Cmd.none
    in
    ( fromTokenAndLocale newToken locale, sessionMsg )


update : Msg -> User -> ( User, Cmd Msg )
update msg user =
    case msg of
        GotApiLoadResponse result ->
            case result of
                Err _ ->
                    ( user, Cmd.none )

                Ok apiResponse ->
                    case apiResponse.data of
                        SessionResponseData serverSession ->
                            let
                                ( locale, localeCmd ) =
                                    Locale.init serverSession.lang

                                newUser =
                                    User
                                        { name = serverSession.name
                                        , preferredLocale = locale
                                        , token = token user
                                        , sessionExpiresAt = apiResponse.expires
                                        }

                                cmd =
                                    Cmd.map GotTranslationFromLocale localeCmd
                            in
                            ( newUser, cmd )

                        _ ->
                            ( user, Cmd.none )

        GotApiSetResponse result ->
            case result of
                Err _ ->
                    ( user, Cmd.none )

                Ok apiResponse ->
                    case apiResponse.data of
                        SessionResponseData _ ->
                            let
                                newUser =
                                    setExpiresAt apiResponse.expires user
                            in
                            ( newUser, Cmd.none )

                        _ ->
                            ( user, Cmd.none )

        GotTranslationFromLocale localeCmd ->
            let
                ( newLocale, _ ) =
                    Locale.update localeCmd <| preferredLocale user
            in
            ( setPreferredLocale newLocale user, Cmd.none )


loadSession : String -> Cmd Msg
loadSession tokenToLoad =
    ServerRequest.loadSession tokenToLoad <| Http.expectJson GotApiLoadResponse apiResponseDecoder


setSession : String -> String -> Cmd Msg
setSession tokenToSet locale =
    ServerRequest.setSession tokenToSet locale <| Http.expectJson GotApiSetResponse apiResponseDecoder
