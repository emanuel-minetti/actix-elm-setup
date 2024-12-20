module ServerRequest exposing (loadSession, loadTranslation, setSession)

import Http
import Json.Encode as E


type alias RequestOptions msg =
    { method : String
    , token : Maybe String
    , expect : Http.Expect msg
    , path : String
    , body : Maybe E.Value
    }


request : RequestOptions msg -> Cmd msg
request options =
    let
        accept_header =
            Http.header "Accept" "application/json"

        headers =
            case options.token of
                Just token ->
                    [ accept_header, Http.header "Authorization" <| "Bearer " ++ token ]

                Nothing ->
                    [ accept_header ]

        body =
            case options.body of
                Just json ->
                    Http.jsonBody json

                Nothing ->
                    Http.emptyBody
    in
    Http.request
        { method = options.method
        , url = "http://127.0.0.1:8080/" ++ options.path
        , headers = headers
        , body = body
        , expect = options.expect
        , timeout = Nothing
        , tracker = Nothing
        }


loadSession : String -> Http.Expect msg -> Cmd msg
loadSession token expect =
    let
        options =
            { method = "GET", token = Just token, expect = expect, path = "api/session", body = Nothing }
    in
    request options


setSession : String -> String -> Http.Expect msg -> Cmd msg
setSession token lang expect =
    let
        jsonBody =
            E.object [ ( "preferred_lang", E.string lang ) ]

        options =
            { method = "POST", token = Just token, expect = expect, path = "api/session", body = Just jsonBody }
    in
    request options


loadTranslation : String -> Http.Expect msg -> Cmd msg
loadTranslation lang expect =
    let
        options =
            { method = "GET", token = Nothing, expect = expect, path = "lang/translation." ++ lang ++ ".json", body = Nothing }
    in
    request options
