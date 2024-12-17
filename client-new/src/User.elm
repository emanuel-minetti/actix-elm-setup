module User exposing (Msg(..), User, init, update)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Http
import Locale exposing (Locale)


type alias User =
    { name : String
    , preferredLocale : Locale
    , token : String
    , sessionExpiresAt : Int
    }


type Msg
    = GotApiResponse (Result Http.Error ApiResponse)
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
        GotApiResponse result ->
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

        GotTranslationFromLocale localeCmd ->
            let
                ( newLocale, _ ) =
                    Locale.update localeCmd user.preferredLocale
            in
            ( { user | preferredLocale = newLocale }, Cmd.none )


loadSession : String -> Cmd Msg
loadSession token =
    Http.request
        { method = "GET"
        , url = "http://127.0.0.1:8080/api/session"
        , headers = [ Http.header "Accept" "application/json", Http.header "Authorization" <| "Bearer " ++ token ]
        , body = Http.emptyBody
        , expect = Http.expectJson GotApiResponse apiResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }
