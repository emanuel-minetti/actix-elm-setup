module Page.Privacy exposing (Model, Msg(..), init, update, view)

import Html exposing (Html, div, h3, text)
import Http
import I18n exposing (I18n)


type alias Model =
    { i18n : I18n
    , infos : List String
    , errors : List String
    }


type Msg
    = LanguageSwitched I18n.Language
    | GotTranslations (Result Http.Error (I18n -> I18n))


init : I18n -> ( Model, Cmd Msg )
init i18n =
    ( { i18n = i18n
      , infos = [ "Loading Translations ..." ]
      , errors = []
      }
    , I18n.loadPrivacy GotTranslations i18n
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTranslations (Err httpError) ->
            let
                newErrors =
                    (I18n.failedLoadingLang model.i18n ++ buildErrorMessage httpError model) :: model.errors

                infoFilter info =
                    not <| (info == "Loading Translations ...") || info == I18n.loadingLang model.i18n

                newInfos =
                    List.filter infoFilter model.infos
            in
            ( { model | errors = newErrors, infos = newInfos }, Cmd.none )

        GotTranslations (Ok updateI18n) ->
            let
                newI18n =
                    updateI18n model.i18n
            in
            ( { model | i18n = newI18n, infos = Maybe.withDefault [] (List.tail model.infos) }, Cmd.none )

        LanguageSwitched lang ->
            let
                ( newI18n, cmd ) =
                    I18n.switchLanguage lang GotTranslations model.i18n
            in
            ( { model | i18n = newI18n, infos = I18n.loadingLang model.i18n :: model.infos }, cmd )


view : Model -> Html Msg
view model =
    div []
        [ h3 []
            [ text (I18n.privacyTitle model.i18n) ]
        , div [] (I18n.privacyContent [] model.i18n)
        ]


buildErrorMessage : Http.Error -> Model -> String
buildErrorMessage httpError model =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            I18n.timeout model.i18n

        Http.NetworkError ->
            I18n.network model.i18n

        Http.BadStatus statusCode ->
            I18n.badStatus model.i18n ++ String.fromInt statusCode

        Http.BadBody message ->
            message
