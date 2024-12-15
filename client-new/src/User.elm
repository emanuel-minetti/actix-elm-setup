module User exposing (Msg(..), User, init, update)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Http
import Locale exposing (Lang)


type alias User =
    { name : String
    , preferredLang : Lang
    , token : String
    , sessionExpiresAt : Int
    }


type Msg
    = GotApiResponse (Result Http.Error ApiResponse)


init : String -> ( User, Cmd Msg )
init token =
    let
        msg =
            if String.length token > 0 then
                loadSession token

            else
                Cmd.none
    in
    ( User "" (Locale.langFromString "") token 0, msg )


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
                                newUser =
                                    { name = serverSession.name
                                    , preferredLang = Locale.langFromString serverSession.lang
                                    , token = user.token
                                    , sessionExpiresAt = apiResponse.expires
                                    }
                            in
                            ( newUser, Cmd.none )

                        _ ->
                            ( user, Cmd.none )


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
