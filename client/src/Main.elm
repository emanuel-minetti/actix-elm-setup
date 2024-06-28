module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, selected, src, value, width)
import Html.Events exposing (onInput)
import Http
import I18n exposing (I18n, Language(..))
import Messages exposing (Messages, viewMessages)
import Page.Privacy as PrivacyPage exposing (Msg(..))
import Route exposing (Route(..))
import Url exposing (Url)


type PageModel
    = NotFoundPageModel
    | HomePageModel
    | PrivacyPageModel PrivacyPage.Model


type alias Model =
    { user : Maybe String
    , i18n : I18n
    , messages : Messages
    , route : Route
    , navKey : Nav.Key
    , pageModel : PageModel
    }


type Msg
    = GotTranslations (Result Http.Error (I18n -> I18n))
    | SwitchLanguage String
    | UrlChanged Url
    | LinkClicked UrlRequest
    | PrivacyPageMsg PrivacyPage.Msg


main : Program String Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        preferredLangFromBrowser =
            flags

        preferredLang =
            Maybe.withDefault I18n.En <| I18n.languageFromString preferredLangFromBrowser

        i18n =
            I18n.init { lang = preferredLang, path = "lang" }

        initialRoute =
            Route.parseUrl url

        initialModel =
            { user = Just "Emu"
            , i18n = i18n
            , messages =
                { infos = [ "Loading Translations ..." ]
                , errors = []
                }
            , route = initialRoute
            , navKey = key
            , pageModel = NotFoundPageModel
            }

        initialCmds =
            [ I18n.loadHeader GotTranslations i18n
            , I18n.loadError GotTranslations i18n
            , I18n.loadFooter GotTranslations i18n
            ]
    in
    ( initialModel
    , Cmd.batch initialCmds
    )
        |> initCurrentPage


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPageModel, Cmd.none )

                Route.Home ->
                    ( HomePageModel, Cmd.none )

                Route.Privacy ->
                    let
                        ( pageModel, pageCmds ) =
                            PrivacyPage.init model.i18n
                    in
                    ( PrivacyPageModel pageModel, Cmd.map PrivacyPageMsg pageCmds )
    in
    ( { model | pageModel = currentPage }, Cmd.batch [ existingCmds, mappedPageCmds ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.pageModel ) of
        ( GotTranslations (Err httpError), _ ) ->
            let
                newErrors =
                    (I18n.failedLoadingLang model.i18n ++ buildErrorMessage httpError model) :: model.messages.errors

                infoFilter info =
                    not <| (info == "Loading Translations ...") || info == I18n.loadingLang model.i18n

                newInfos =
                    List.filter infoFilter model.messages.errors
            in
            ( { model | messages = { errors = newErrors, infos = newInfos } }, Cmd.none )

        ( GotTranslations (Ok updateI18n), _ ) ->
            let
                newI18n =
                    updateI18n model.i18n
            in
            ( { model | i18n = newI18n, messages = Messages.removeFirstInfo model.messages }, Cmd.none )

        ( SwitchLanguage langString, _ ) ->
            let
                lang =
                    Maybe.withDefault I18n.En <| I18n.languageFromString langString

                ( newI18n, mainCmd ) =
                    I18n.switchLanguage lang GotTranslations model.i18n

                pageCmd =
                    case model.pageModel of
                        PrivacyPageModel pageModel ->
                            PrivacyPage.update (PrivacyPage.LanguageSwitched lang) pageModel
                                |> Tuple.second
                                |> Cmd.map PrivacyPageMsg

                        _ ->
                            Cmd.none

                cmd =
                    Cmd.batch [ mainCmd, pageCmd ]
            in
            ( { model | i18n = newI18n, messages = Messages.addInfo model.messages (I18n.loadingLang model.i18n) }, cmd )

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( PrivacyPageMsg subMsg, PrivacyPageModel pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    PrivacyPage.update subMsg pageModel
            in
            ( { model | pageModel = PrivacyPageModel updatedPageModel }, Cmd.map PrivacyPageMsg updatedCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = viewBody model
    }


viewBody : Model -> List (Html Msg)
viewBody model =
    [ viewHeader model
    , viewMessages model.messages
    , viewCurrentPage model
    , viewFooter model
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


viewCurrentPage : Model -> Html Msg
viewCurrentPage model =
    case model.pageModel of
        NotFoundPageModel ->
            viewNotFoundPage model

        HomePageModel ->
            viewHomePage model

        PrivacyPageModel pageModel ->
            PrivacyPage.view pageModel
                |> Html.map PrivacyPageMsg


viewNotFoundPage : Model -> Html msg
viewNotFoundPage _ =
    h3 [] [ text "Oops! The page you requested was not found!" ]


viewHomePage : Model -> Html msg
viewHomePage _ =
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


viewFooter : Model -> Html Msg
viewFooter model =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ]
                        [ li [] [ a [ href "/privacy" ] [ text <| I18n.footerPrivacy model.i18n ] ]
                        , li [] [ text <| I18n.imprint model.i18n ]
                        ]
                    ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
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
