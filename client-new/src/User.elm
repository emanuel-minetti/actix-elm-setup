module User exposing (Msg(..), User, init, name, preferredLocale, setSession, token, update)

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


fromToken : String -> User
fromToken newToken =
    let
        ( locale, _ ) =
            Locale.init ""
    in
    User { name = "", preferredLocale = locale, token = newToken, sessionExpiresAt = 0 }


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


setPreferredLocale : User -> Locale -> User
setPreferredLocale user locale =
    case user of
        User record ->
            User { record | preferredLocale = locale }


type Msg
    = GotApiLoadResponse (Result Http.Error ApiResponse)
    | GotApiSetResponse (Result Http.Error ApiResponse)
    | GotTranslationFromLocale Locale.Msg


init : String -> ( User, Cmd Msg )
init newToken =
    let
        sessionMsg =
            if String.length newToken > 0 then
                loadSession newToken

            else
                Cmd.none
    in
    ( fromToken newToken, sessionMsg )


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
                            ( user, Cmd.none )

                        _ ->
                            ( user, Cmd.none )

        GotTranslationFromLocale localeCmd ->
            let
                ( newLocale, _ ) =
                    Locale.update localeCmd <| preferredLocale user
            in
            ( setPreferredLocale user newLocale, Cmd.none )


loadSession : String -> Cmd Msg
loadSession tokenToLoad =
    ServerRequest.loadSession tokenToLoad <| Http.expectJson GotApiLoadResponse apiResponseDecoder


setSession : String -> String -> Cmd Msg
setSession tokenToSet locale =
    ServerRequest.setSession tokenToSet locale <| Http.expectJson GotApiSetResponse apiResponseDecoder
