module Main exposing (main)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, selected, src, value, width)
import Html.Events exposing (onInput)
import Http
import I18n exposing (I18n, Language(..))


type alias Model =
    { user : Maybe String
    , i18n : I18n
    , infos : List String
    , errors : List String
    }


type Msg
    = GotTranslations (Result Http.Error (I18n -> I18n))
    | SwitchLanguage String


main : Program String Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : String -> ( Model, Cmd Msg )
init flags =
    let
        preferredLangFromBrowser =
            flags

        preferredLang =
            Maybe.withDefault I18n.En <| I18n.languageFromString preferredLangFromBrowser

        i18n =
            I18n.init { lang = preferredLang, path = "lang" }
    in
    ( { user = Just "Emu"
      , i18n = i18n
      , infos = [ "Loading Translations ..." ]
      , errors = []
      }
    , Cmd.batch [ I18n.loadHeader GotTranslations i18n, I18n.loadError GotTranslations i18n ]
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

        SwitchLanguage langString ->
            let
                lang =
                    Maybe.withDefault I18n.En <| I18n.languageFromString langString

                ( newI18n, cmd ) =
                    I18n.switchLanguage lang GotTranslations model.i18n
            in
            ( { model | i18n = newI18n, infos = I18n.loadingLang model.i18n :: model.infos }, cmd )


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = viewBody model
    }


viewBody : Model -> List (Html Msg)
viewBody model =
    [ viewHeader model
    , viewMessages model
    , viewErrors model
    , div []
        [ h1 [] [ text "Welcome to Emu's Test!" ]
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
    ]


viewHeader : Model -> Html Msg
viewHeader model =
    header []
        [ nav [ class "navbar bg-body-tertiary" ]
            [ div [ class "container-fluid" ]
                [ a
                    [ class "navbar-brand", href "/" ]
                    [ img
                        [ src "img/logo-color.png"
                        , alt "Logo"
                        , width 30
                        , height 24
                        , class "d-inline-block align-text-top me-3"
                        ]
                        []
                    , text "Actix Elm Setup"
                    ]
                , span [ class "navbar-text" ] [ viewLoginText model ]
                , select [ onInput SwitchLanguage ] <| viewSelectOptions model
                ]
            ]
        ]


viewLoginText : Model -> Html msg
viewLoginText model =
    case model.user of
        Nothing ->
            text (I18n.notLoggedIn model.i18n)

        Just userName ->
            text (I18n.loggedInAs model.i18n ++ userName)


viewSelectOptions : Model -> List (Html Msg)
viewSelectOptions model =
    let
        langToFunc : I18n.Language -> (I18n -> String)
        langToFunc lang =
            case lang of
                En ->
                    I18n.english

                De ->
                    I18n.german

        langToOption : I18n.Language -> Html Msg
        langToOption lang =
            option
                [ value (I18n.languageToString lang)
                , selected (lang == I18n.arrivedLanguage model.i18n)
                ]
                [ text (langToFunc lang model.i18n) ]
    in
    List.map langToOption I18n.languages


viewMessages model =
    viewInfos model


viewInfos : Model -> Html msg
viewInfos model =
    let
        viewEntry message =
            li [] [ text message ]
    in
    if List.length model.infos == 0 then
        text ""

    else if List.length model.infos > 1 then
        ul [ class "text-center alert alert-light" ] (List.map viewEntry model.infos)

    else
        div [ class "text-center alert alert-light" ] [ text (Maybe.withDefault "" (List.head model.infos)) ]


viewErrors : Model -> Html msg
viewErrors model =
    let
        viewEntry message =
            li [] [ text message ]
    in
    if List.length model.errors == 0 then
        text ""

    else if List.length model.errors > 1 then
        ul [ class "text-center alert alert-danger" ] (List.map viewEntry model.errors)

    else
        div [ class "text-center alert alert-danger" ] [ text (Maybe.withDefault "" (List.head model.errors)) ]


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
