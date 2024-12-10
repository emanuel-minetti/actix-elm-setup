module Locale exposing (Locale, Msg(..), changeLang, changeTranslations, getLocaleOptions, init, initialLocale, toText, toValue, update)

import Array exposing (Array)
import Http
import I18Next exposing (Translations, initialTranslations, translationsDecoder)
import Translations.Lang as I18n


type alias Locale =
    { lang : Lang
    , t : Translations
    }


type Msg
    = GotTranslation (Result Http.Error Translations)
    | SwitchLanguage String


init : Array String -> ( Locale, Cmd Msg )
init flags =
    let
        newLocale =
            initialLocale flags
    in
    ( newLocale, loadTranslation newLocale )


update : Msg -> Locale -> ( Locale, Cmd Msg )
update msg locale =
    case msg of
        GotTranslation result ->
            case result of
                Err _ ->
                    ( locale, Cmd.none )

                Ok translation ->
                    let
                        newLocale =
                            changeTranslations locale translation
                    in
                    ( newLocale, Cmd.none )

        SwitchLanguage newValue ->
            let
                newLocale =
                    changeLang locale newValue
            in
            ( newLocale, loadTranslation newLocale )


initialLocale : Array String -> Locale
initialLocale flags =
    let
        defaultLangString =
            "de"

        langFromBrowser =
            Array.get 0 flags
                |> Maybe.withDefault defaultLangString
                |> String.slice 0 2

        lang =
            fromString langFromBrowser
    in
    { lang = lang, t = initialTranslations }


getLocaleOptions : List Locale
getLocaleOptions =
    let
        localeFromLang lang =
            { lang = lang, t = initialTranslations }
    in
    List.map localeFromLang <| getLangList


changeLang : Locale -> String -> Locale
changeLang locale string =
    let
        lang =
            fromString string
    in
    { locale | lang = lang }


changeTranslations : Locale -> Translations -> Locale
changeTranslations locale translations =
    { locale | t = translations }


toValue : Locale -> String
toValue locale =
    case locale.lang of
        De ->
            "de"

        En ->
            "en"


toText : Locale -> Translations -> String
toText locale translations =
    case locale.lang of
        De ->
            I18n.german translations

        En ->
            I18n.english translations


type Lang
    = De
    | En


getLangList : List Lang
getLangList =
    [ De, En ]


fromString : String -> Lang
fromString string =
    case string of
        "de" ->
            De

        "en" ->
            En

        _ ->
            De


loadTranslation : Locale -> Cmd Msg
loadTranslation locale =
    Http.request
        { method = "GET"
        , url = "http://127.0.0.1:8080/lang/translation." ++ toValue locale ++ ".json"
        , headers = [ Http.header "Accept" "application/json" ]
        , body = Http.emptyBody
        , expect = Http.expectJson GotTranslation translationsDecoder
        , timeout = Nothing
        , tracker = Nothing
        }



--viewLangOptions : Locale -> List (Html msg)
--viewLangOptions locale =
--    let
--        localeToText newLocale =
--            toText newLocale
--
--        isSelected newLocale =
--            newLocale.lang == locale.lang
--
--        langToOption newLocale =
--            option [ value <| toValue newLocale, selected <| isSelected newLocale ] [ text <| localeToText newLocale locale.t ]
--    in
--    List.map langToOption getLocaleOptions
