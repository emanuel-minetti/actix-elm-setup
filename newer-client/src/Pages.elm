module Pages exposing (Page(..), toPath, toText)


type Page
    = Imprint
    | Privacy


toText : Page -> String
toText page =
    case page of
        Imprint ->
            "Impressum"

        Privacy ->
            "Privacy Declaration"


toPath : Page -> String
toPath page =
    case page of
        Imprint ->
            "imprint"

        Privacy ->
            "privacy"
