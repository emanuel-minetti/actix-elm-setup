module Page.Home exposing (..)

import Html exposing (Html, div, h1, p, strong, text)
import Http
import I18n exposing (I18n)
import Messages exposing (Messages)


type alias Model =
    { i18n : I18n
    , messages : Messages
    }


type Msg
    = LanguageSwitched I18n.Language
    | GotTranslations (Result Http.Error (I18n -> I18n))


init : I18n -> ( Model, Cmd Msg )
init i18n =
    ( { i18n = i18n
      , messages =
            { infos = [ "Loading Translations ..." ]
            , errors = []
            }
      }
      --todo localize
    , I18n.loadImprint GotTranslations i18n
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTranslations (Err httpError) ->
            let
                newErrors =
                    (I18n.failedLoadingLang model.i18n ++ Messages.buildErrorMessage httpError model.i18n)
                        :: model.messages.errors

                infoFilter info =
                    not <| (info == "Loading Translations ...") || info == I18n.loadingLang model.i18n

                newInfos =
                    List.filter infoFilter model.messages.infos
            in
            ( { model | messages = { errors = newErrors, infos = newInfos } }, Cmd.none )

        GotTranslations (Ok updateI18n) ->
            let
                newI18n =
                    updateI18n model.i18n
            in
            ( { model | i18n = newI18n, messages = Messages.removeFirstInfo model.messages }, Cmd.none )

        LanguageSwitched lang ->
            let
                ( newI18n, cmd ) =
                    I18n.switchLanguage lang GotTranslations model.i18n
            in
            ( { model | i18n = newI18n, messages = Messages.addInfo model.messages (I18n.loadingLang model.i18n) }, cmd )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Welcome to Emu's Homepage!" ]
        , p []
            [ text "Emus Test nanu Inc. (stock symbol "
            , strong [] [ text "DMI" ]
            , text <|
                """
                    ) is a micro-cap regional paper and office
                    supply distributor with an emphasis on servicing
                    small-business clients.
                    """
            ]
        ]
