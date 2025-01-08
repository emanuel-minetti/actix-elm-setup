module User exposing (Msg(..), User, fromToken, init, loadSession, name, setSession, setToken, token, update)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Http
import ServerRequest


type User
    = User
        { name : String
        , token : String
        , sessionExpiresAt : Int
        }



--GETTERS


name : User -> String
name user =
    case user of
        User record ->
            record.name


token : User -> String
token user =
    case user of
        User record ->
            record.token



--CONSTRUCTORS AND SETTERS


fromToken : String -> User
fromToken newToken =
    User { name = "", token = newToken, sessionExpiresAt = 0 }


setToken : String -> User -> User
setToken newToken user =
    case user of
        User record ->
            User { record | token = newToken }


setExpiresAt : Int -> User -> User
setExpiresAt expiresAt user =
    case user of
        User record ->
            User { record | sessionExpiresAt = expiresAt }


type Msg
    = GotApiLoadResponse (Result Http.Error ApiResponse)
    | GotApiSetResponse (Result Http.Error ApiResponse)


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
                                newUser =
                                    User
                                        { name = serverSession.name
                                        , token = token user
                                        , sessionExpiresAt = apiResponse.expires
                                        }
                            in
                            ( newUser, Cmd.none )

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


loadSession : String -> Cmd Msg
loadSession tokenToLoad =
    ServerRequest.loadSession tokenToLoad <| Http.expectJson GotApiLoadResponse apiResponseDecoder


setSession : String -> String -> Cmd Msg
setSession tokenToSet locale =
    ServerRequest.setSession tokenToSet locale <| Http.expectJson GotApiSetResponse apiResponseDecoder
