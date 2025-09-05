module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Api
import Api.Translations
import Dict
import Effect exposing (Effect)
import Json.Decode
import Locale
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    { browserLang : String
    , token : String
    , expires : Int
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.field "flags"
        (Json.Decode.map3 Flags
            (Json.Decode.field "lang" Json.Decode.string)
            (Json.Decode.field "savedSessionToken" Json.Decode.string)
            (Json.Decode.field "expires" Json.Decode.int)
        )



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult _ =
    let
        -- TODO here to set user if applicable
        lang =
            case flagsResult of
                Ok value ->
                    String.left 2 value.browserLang

                Err _ ->
                    "de"
    in
    ( { translationsApiData = Api.Loading
      , locale = Locale.init lang
      , user = Nothing
      }
    , Api.Translations.get { lang = lang, onResponse = Shared.Msg.TranslationsApiResponded }
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        Shared.Msg.TranslationsApiResponded result ->
            let
                locale =
                    model.locale

                newLocale =
                    case result of
                        Ok translations ->
                            { locale | t = translations }

                        Err _ ->
                            locale

                newTranslationsApiData =
                    case result of
                        Ok translations ->
                            Api.Success translations

                        Err error ->
                            Api.Failure error
            in
            ( { model | locale = newLocale, translationsApiData = newTranslationsApiData }, Effect.none )

        Shared.Msg.LoginApiResponded user ->
            let
                userLang =
                    String.toLower user.preferredLang

                needToLoadTranslations =
                    userLang /= Locale.toLanguageValue model.locale.lang

                langEffect =
                    case needToLoadTranslations of
                        True ->
                            Api.Translations.get { lang = userLang, onResponse = Shared.Msg.TranslationsApiResponded }

                        False ->
                            Effect.none

                locale =
                    case needToLoadTranslations of
                        True ->
                            Locale.init userLang

                        False ->
                            model.locale
            in
            ( { model | user = Just user, locale = locale }
            , Effect.batch
                [ langEffect
                , Effect.pushRoute
                    { path = Route.Path.Home_
                    , query = Dict.empty
                    , hash = Nothing
                    }
                , Effect.saveUser user
                ]
            )

        Shared.Msg.Logout ->
            ( { model | user = Nothing }
            , Effect.clearUser
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
