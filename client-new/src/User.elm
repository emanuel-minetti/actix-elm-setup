module User exposing (Msg(..), User, get, init)

import Http
import Json.Decode as D
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
            loadSession token
    in
    ( initialUser, msg )


initialUser : User
initialUser =
    User "" (Locale.langFromString "") "" 0


get : String -> ServerSession -> User
get token serverSession =
    { name = serverSession.name
    , preferredLang = Locale.langFromString serverSession.preferredLang
    , token = token
    , sessionExpiresAt = 0
    }


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


type alias ServerSession =
    { name : String
    , preferredLang : String
    }


sessionDecoder : D.Decoder ServerSession
sessionDecoder =
    D.map2 ServerSession (D.field "name" D.string) (D.field "preferred_lang" D.string)


type alias ApiResponse =
    { expiresAt : Int
    , error : String
    , data : ServerSession
    }


apiResponseDecoder : D.Decoder ApiResponse
apiResponseDecoder =
    D.map3 ApiResponse (D.field "expires_at" D.int) (D.field "error" D.string) (D.field "data" sessionDecoder)
