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


init : String -> ( Maybe User, Cmd Msg )
init token =
    let
        msg =
            loadSession token
    in
    ( Nothing, msg )


update : Msg -> String -> ( Maybe User, Cmd Msg )
update msg token =
    case msg of
        GotApiResponse result ->
            case result of
                Err _ ->
                    ( Nothing, Cmd.none )

                Ok apiResponse ->
                    case apiResponse.data of
                        SessionResponseData serverSession ->
                            let
                                newUser =
                                    { name = serverSession.name
                                    , preferredLang = Locale.langFromString serverSession.lang
                                    , token = token
                                    , sessionExpiresAt = apiResponse.expires
                                    }
                            in
                            ( Just newUser, Cmd.none )

                        _ ->
                            ( Nothing, Cmd.none )


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
