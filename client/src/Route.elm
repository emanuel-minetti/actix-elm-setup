module Route exposing (Route(..), needsAuthentication, parseUrl, toHref, toText)

import Locale exposing (Locale)
import Translations.Route as I18n
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Home
    | Privacy
    | Imprint
    | Login


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Home top
        , map Home (s "home")
        , map Privacy (s "privacy")
        , map Imprint (s "imprint")
        , map Login (s "login")
        ]


toHref : Route -> String
toHref route =
    case route of
        Privacy ->
            "/privacy"

        Imprint ->
            "/imprint"

        Login ->
            "/login"

        _ ->
            "/"


toText : Route -> Locale -> String
toText route locale =
    case route of
        Privacy ->
            I18n.privacy locale.t

        Imprint ->
            I18n.imprint locale.t

        _ ->
            ""


needsAuthentication : Route -> Bool
needsAuthentication route =
    let
        routesWithoutAuthentication =
            [ NotFound, Privacy, Imprint, Login ]
    in
    not <| List.member route routesWithoutAuthentication
