module User exposing (Msg(..), User, init, setSession, update)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Http
import Locale exposing (Locale)
import ServerRequest


type alias User =
    { name : String
    , preferredLocale : Locale
    , token : String
    , sessionExpiresAt : Int
    }


type Msg
    = GotApiLoadResponse (Result Http.Error ApiResponse)
    | GotApiSetResponse (Result Http.Error ApiResponse)
    | GotTranslationFromLocale Locale.Msg


init : String -> ( User, Cmd Msg )
init token =
    let
        sessionMsg =
            if String.length token > 0 then
                loadSession token

            else
                Cmd.none

        ( locale, _ ) =
            Locale.init ""
    in
    ( User "" locale token 0, sessionMsg )


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
                                    { name = serverSession.name
                                    , preferredLocale = locale
                                    , token = user.token
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
                    Locale.update localeCmd user.preferredLocale
            in
            ( { user | preferredLocale = newLocale }, Cmd.none )


loadSession : String -> Cmd Msg
loadSession token =
    ServerRequest.loadSession token <| Http.expectJson GotApiLoadResponse apiResponseDecoder


setSession : String -> String -> Cmd Msg
setSession token locale =
    ServerRequest.setSession token locale <| Http.expectJson GotApiSetResponse apiResponseDecoder
