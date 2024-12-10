module Route exposing (Route(..), parseUrl, routeToHref, routeToText)

import Locale exposing (Locale)
import Translations.Route as I18n
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Home
    | Privacy
    | Imprint


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
        ]


routeToHref : Route -> String
routeToHref route =
    case route of
        Privacy ->
            "/privacy"

        Imprint ->
            "/imprint"

        _ ->
            "/"


routeToText : Route -> Locale -> String
routeToText route locale =
    case route of
        Privacy ->
            I18n.privacy locale.t

        Imprint ->
            I18n.imprint locale.t

        _ ->
            ""
