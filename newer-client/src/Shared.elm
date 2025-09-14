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
import Api.Session
import Api.Session.Model
import Api.Translations
import Effect exposing (Effect)
import Json.Decode
import Locale
import Route exposing (Route)
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    { browserLang : String
    , token : String
    , expires : Int
    , nowPlusSome : Int
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.field "flags"
        (Json.Decode.map4 Flags
            (Json.Decode.field "lang" Json.Decode.string)
            (Json.Decode.field "savedSessionToken" Json.Decode.string)
            (Json.Decode.field "expires" Json.Decode.int)
            (Json.Decode.field "nowPlusSome" Json.Decode.int)
        )



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult _ =
    case flagsResult of
        Ok flags ->
            let
                needsToSetUser =
                    not (String.isEmpty flags.token)
                        && (flags.expires /= 0)
                        && (flags.expires * 1000 > flags.nowPlusSome)

                ( newModel, newEffect ) =
                    case needsToSetUser of
                        True ->
                            ( { translationsApiData = Api.Loading
                              , isRestoringSession = True
                              , locale = Locale.init flags.browserLang
                              , user = Nothing
                              , globalErrors = []
                              }
                            , Effect.batch
                                [ Api.Session.get
                                    { token = flags.token
                                    , onResponse = Shared.Msg.RestoreSessionApiResponded flags.token
                                    }
                                , Api.Translations.get
                                    { lang = flags.browserLang
                                    , onResponse = Shared.Msg.TranslationsApiResponded
                                    }
                                ]
                            )

                        False ->
                            noUser flags.browserLang
            in
            ( newModel, newEffect )

        Err _ ->
            noUser "de"


noUser : String -> ( Model, Effect Msg )
noUser lang =
    ( { translationsApiData = Api.Loading
      , isRestoringSession = False
      , locale = Locale.init lang
      , user = Nothing
      , globalErrors = []
      }
    , Api.Translations.get { lang = lang, onResponse = Shared.Msg.TranslationsApiResponded }
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
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

        Shared.Msg.LoginSucceeded user path ->
            let
                userLang =
                    String.toLower user.preferredLang

                needToLoadTranslations =
                    userLang /= Locale.toLanguageStringValue model.locale.lang

                langEffect =
                    if needToLoadTranslations then
                        Effect.changeLocale userLang

                    else
                        Effect.none
            in
            ( { model | user = Just user }
            , Effect.batch
                [ langEffect
                , Effect.pushRoutePath path
                , Effect.saveUser user
                ]
            )

        Shared.Msg.ChangeLocale newValue ->
            let
                langEffect =
                    Api.Translations.get { lang = newValue, onResponse = Shared.Msg.TranslationsApiResponded }

                locale =
                    Locale.init newValue

                storageEffect =
                    Effect.saveLang locale

                serverEffect =
                    case model.user of
                        Just user ->
                            Api.Session.post
                                { lang = newValue
                                , token = user.token
                                , onResponse = Shared.Msg.ChangeLocaleResponded
                                }

                        Nothing ->
                            Effect.none
            in
            ( { model | locale = locale }, Effect.batch [ langEffect, storageEffect, serverEffect ] )

        Shared.Msg.Logout ->
            ( { model | user = Nothing }
            , Effect.clearUser
            )

        Shared.Msg.RestoreSessionApiResponded token apiResult ->
            case apiResult of
                Ok apiResponseData ->
                    let
                        hasError =
                            not <| String.isEmpty apiResponseData.error
                    in
                    if hasError then
                        ( { model | isRestoringSession = False }, Effect.none )

                    else
                        case apiResponseData.data of
                            Api.ResponseData sessionData ->
                                let
                                    userLang =
                                        sessionData
                                            |> Api.Session.Model.lang
                                            |> String.toLower

                                    needToLoadTranslations =
                                        Locale.toLanguageStringValue model.locale.lang /= userLang

                                    locale =
                                        case needToLoadTranslations of
                                            True ->
                                                Locale.init userLang

                                            False ->
                                                model.locale
                                in
                                ( { model | locale = locale, isRestoringSession = False }
                                , Effect.batch
                                    [ Effect.login
                                        { token = token
                                        , expires = apiResponseData.expires
                                        , name = Api.Session.Model.name sessionData
                                        , preferredLang = Api.Session.Model.lang sessionData
                                        }
                                        route.path
                                    , Api.Translations.get
                                        { lang = userLang, onResponse = Shared.Msg.TranslationsApiResponded }
                                    ]
                                )

                            Api.NoneResponseData _ ->
                                ( { model | isRestoringSession = False }, Effect.none )

                Err _ ->
                    ( { model | isRestoringSession = False }, Effect.none )

        Shared.Msg.ChangeLocaleResponded apiResult ->
            case apiResult of
                Ok apiResponseData ->
                    let
                        hasError =
                            not <| String.isEmpty apiResponseData.error
                    in
                    if hasError then
                        -- TODO handle: i.e. session timed out
                        ( model, Effect.none )

                    else
                        case apiResponseData.data of
                            Api.ResponseData sessionData ->
                                let
                                    newUser =
                                        case model.user of
                                            Just user ->
                                                let
                                                    preferredLang =
                                                        Api.Session.Model.lang sessionData
                                                in
                                                Just { user | preferredLang = preferredLang }

                                            Nothing ->
                                                model.user
                                in
                                ( { model | user = newUser }, Effect.none )

                            Api.NoneResponseData _ ->
                                ( model, Effect.none )

                Err _ ->
                    ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
