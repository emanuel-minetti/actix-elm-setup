module Locale exposing (Locale, changeLang, changeTranslations, getLocaleOptions, initialLocale, toText, toValue)

import Array exposing (Array)
import I18Next exposing (Translations, initialTranslations)
import Translations.Lang as I18n


type alias Locale =
    { lang : Lang
    , t : Translations
    }


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
