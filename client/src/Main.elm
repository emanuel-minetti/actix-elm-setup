module Main exposing (main)

import ApiResponse exposing (ApiResponse, ApiResponseData(..), apiResponseDecoder)
import Array exposing (Array)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, id, selected, src, value, width)
import Html.Events exposing (onClick, onInput)
import Http
import I18n exposing (I18n, Language(..))
import Messages exposing (Messages)
import Page.Home as HomePage
import Page.Imprint as ImprintPage
import Page.Privacy as PrivacyPage exposing (Msg(..))
import Route exposing (Route)
import Task
import Url exposing (Protocol(..), Url)


type PageModel
    = NotFoundPageModel
    | HomePageModel HomePage.Model
    | PrivacyPageModel PrivacyPage.Model
    | ImprintPageModel ImprintPage.Model


type alias Session =
    { name : String
    , preferred_lang : I18n.Language
    , expires_at : Int
    }


type alias Model =
    { auth_token : Maybe String
    , session : Maybe Session
    , i18n : I18n
    , messages : Messages
    , route : Route
    , navKey : Nav.Key
    , pageModel : PageModel
    }


type Msg
    = GotTranslations (Result Http.Error (I18n -> I18n))
    | GotSession (Result Http.Error ApiResponse)
    | SwitchLanguage String
    | UrlChanged Url
    | LinkClicked UrlRequest
    | GoToRoute Route
    | HomePageMsg HomePage.Msg
    | PrivacyPageMsg PrivacyPage.Msg
    | ImprintPageMsg ImprintPage.Msg


main : Program (Array String) Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : Array String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        preferredLangFromBrowser =
            Maybe.withDefault "en" <| Array.get 0 flags

        preferredLang =
            Maybe.withDefault I18n.En <| I18n.languageFromString preferredLangFromBrowser

        i18n =
            I18n.init { lang = preferredLang, path = "lang" }

        i18nCmds =
            [ I18n.loadHeader GotTranslations i18n
            , I18n.loadError GotTranslations i18n
            , I18n.loadFooter GotTranslations i18n
            ]

        sessionTokenFromBrowser =
            Maybe.withDefault "" <| Array.get 1 flags

        sessionCmd =
            if sessionTokenFromBrowser == "" then
                Cmd.none

            else
                getSession sessionTokenFromBrowser

        initialRoute =
            Route.parseUrl url

        initialModel =
            { auth_token = Nothing
            , session = Nothing

            --, user = Just "Emu"
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
            sessionCmd :: i18nCmds
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
                    let
                        ( pageModel, pageCmds ) =
                            HomePage.init model.i18n
                    in
                    ( HomePageModel pageModel, Cmd.map HomePageMsg pageCmds )

                Route.Privacy ->
                    let
                        ( pageModel, pageCmds ) =
                            PrivacyPage.init model.i18n
                    in
                    ( PrivacyPageModel pageModel, Cmd.map PrivacyPageMsg pageCmds )

                Route.Imprint ->
                    let
                        ( pageModel, pageCmds ) =
                            ImprintPage.init model.i18n
                    in
                    ( ImprintPageModel pageModel, Cmd.map ImprintPageMsg pageCmds )
    in
    ( { model | pageModel = currentPage }, Cmd.batch [ existingCmds, mappedPageCmds ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.pageModel ) of
        ( GotTranslations (Err httpError), _ ) ->
            let
                newErrors =
                    (I18n.failedLoadingLang model.i18n ++ Messages.buildErrorMessage httpError model.i18n)
                        :: model.messages.errors

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

        ( GotSession (Ok resp), _ ) ->
            let
                sessionResponseData =
                    case resp.data of
                        SessionResponseData srd ->
                            srd

                        _ ->
                            { name = "", lang = "En" }

                name =
                    sessionResponseData.name

                langFromSession =
                    sessionResponseData.lang

                preferredLang =
                    Maybe.withDefault I18n.En <| I18n.languageFromString <| String.toLower langFromSession

                expires =
                    resp.expires

                session =
                    Just (Session name preferredLang expires)

                preferredLangString =
                    String.toLower <| I18n.languageToString preferredLang
            in
            ( { model | session = session }, run (SwitchLanguage preferredLangString) )

        ( GotSession (Err resp), _ ) ->
            let
                _ =
                    Debug.log "Error from Elm: " resp

                session =
                    Nothing
            in
            ( { model | session = session }, Cmd.none )

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

                        ImprintPageModel pageModel ->
                            ImprintPage.update (ImprintPage.LanguageSwitched lang) pageModel
                                |> Tuple.second
                                |> Cmd.map ImprintPageMsg

                        _ ->
                            Cmd.none

                cmd =
                    Cmd.batch [ mainCmd, pageCmd ]
            in
            ( { model | i18n = newI18n, messages = Messages.addInfo model.messages (I18n.loadingLang model.i18n) }
            , cmd
            )

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

        ( GoToRoute route, _ ) ->
            let
                cmd =
                    Route.pushUrl route model.navKey
            in
            ( model, cmd )
                |> initCurrentPage

        ( HomePageMsg subMsg, HomePageModel pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    HomePage.update subMsg pageModel
            in
            ( { model | pageModel = HomePageModel updatedPageModel }, Cmd.map HomePageMsg updatedCmd )

        ( PrivacyPageMsg subMsg, PrivacyPageModel pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    PrivacyPage.update subMsg pageModel
            in
            ( { model | pageModel = PrivacyPageModel updatedPageModel }, Cmd.map PrivacyPageMsg updatedCmd )

        ( ImprintPageMsg subMsg, ImprintPageModel pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ImprintPage.update subMsg pageModel
            in
            ( { model | pageModel = ImprintPageModel updatedPageModel }, Cmd.map ImprintPageMsg updatedCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


run : msg -> Cmd msg
run m =
    Task.perform (always m) (Task.succeed ())


view : Model -> Document Msg
view model =
    { title = "Actix Elm Setup"
    , body = viewBody model
    }


viewBody : Model -> List (Html Msg)
viewBody model =
    [ viewHeader model
    , Messages.viewMessages model.messages
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
    case model.session of
        Nothing ->
            text (I18n.notLoggedIn model.i18n)

        Just session ->
            text (I18n.loggedInAs model.i18n ++ session.name)


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
    let
        page =
            case model.pageModel of
                NotFoundPageModel ->
                    viewNotFoundPage model

                HomePageModel pageModel ->
                    HomePage.view pageModel
                        |> Html.map HomePageMsg

                --HomePageModel ->
                --    viewHomePage model
                PrivacyPageModel pageModel ->
                    PrivacyPage.view pageModel
                        |> Html.map PrivacyPageMsg

                ImprintPageModel pageModel ->
                    ImprintPage.view pageModel
                        |> Html.map ImprintPageMsg
    in
    div [ id "content", class "container" ] [ page ]


viewNotFoundPage : Model -> Html msg
viewNotFoundPage _ =
    h3 [] [ text "Oops! The page you requested was not found!" ]



--viewHomePage : Model -> Html msg
--viewHomePage _ =
--    div []
--        [ h1 [] [ text "Welcome to Emu's Homepage!" ]
--        , p []
--            [ text "Emus Test nanu Inc. (stock symbol "
--            , strong [] [ text "DMI" ]
--            , text <|
--                """
--                    ) is a micro-cap regional paper and office
--                    supply distributor with an emphasis on servicing
--                    small-business clients.
--                    """
--            ]
--        ]


viewFooter : Model -> Html Msg
viewFooter model =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ]
                        [ li [] [ button [ onClick <| GoToRoute Route.Privacy ] [ text <| I18n.footerPrivacy model.i18n ] ]
                        , li [] [ button [ onClick <| GoToRoute Route.Imprint ] [ text <| I18n.footerImprint model.i18n ] ]
                        ]
                    ]
                , div [ class "col" ]
                    --todo get from config
                    [ span [ class "float-end" ] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]


getSession : String -> Cmd Msg
getSession sessionToken =
    let
        headers =
            [ Http.header "Accept" "application/json", Http.header "Authorization" ("Bearer " ++ sessionToken) ]
    in
    Http.request
        { method = "GET"
        , url = "http://localhost:8080/api/session"
        , headers = headers
        , body = Http.emptyBody
        , expect = Http.expectJson GotSession apiResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }
