module Layouts.MainLayout exposing (Model, Msg(..), Props, layout)

import Api exposing (Data(..))
import Effect exposing (Effect)
import Error exposing (Error)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import I18Next exposing (Translations)
import Layout exposing (Layout)
import Locale exposing (Language, Locale)
import Pages
import Route exposing (Route)
import Shared
import Time
import Translations.Error as I18nError
import Translations.MainLayout as I18n
import View exposing (View)


type alias Props =
    {}


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout _ shared _ =
    Layout.new
        { init = init
        , update = update shared
        , view = view shared
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { secsToExpire : Int
    , fiveMinutesModalShown : Bool
    , expiredModalShown : Bool
    }


init : () -> ( Model, Effect Msg )
init _ =
    ( Model 0 False False, Effect.none )



-- UPDATE


type Msg
    = Logout
    | ChangeLanguage String
    | ErrorsDismissed
    | Tick Time.Posix
    | RenewSession


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Logout ->
            ( model, Effect.logout )

        ChangeLanguage value ->
            let
                effect =
                    if List.member value (List.map Locale.toLanguageStringValue Locale.languages) then
                        Effect.changeLocale value

                    else
                        Effect.none
            in
            ( model, effect )

        ErrorsDismissed ->
            ( model, Effect.clearErrors )

        Tick newTime ->
            let
                secsToExpire : Int
                secsToExpire =
                    case shared.user of
                        Just user ->
                            (user.expires * 1000 - Time.posixToMillis newTime) // 1000

                        Nothing ->
                            0

                newModel : Model
                newModel =
                    { model | secsToExpire = secsToExpire }
            in
            case shared.user of
                Just _ ->
                    -- TODO adjust
                    if secsToExpire > 1 && secsToExpire <= 28 * 60 && not model.expiredModalShown then
                        ( { newModel | expiredModalShown = True }
                        , Effect.showExpiredModal
                        )

                    else if secsToExpire <= 29 * 60 && not model.fiveMinutesModalShown then
                        ( { newModel | fiveMinutesModalShown = True }
                        , Effect.showFiveMinutesModal
                        )

                    else
                        ( newModel, Effect.none )

                Nothing ->
                    ( newModel, Effect.none )

        RenewSession ->
            let
                newModel : Model
                newModel =
                    { model | fiveMinutesModalShown = False }
            in
            case shared.user of
                Just user ->
                    ( newModel, Effect.renewSession user.token )

                Nothing ->
                    ( newModel, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    -- every sec
    Time.every 1000 Tick



-- VIEW


view :
    Shared.Model
    -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model }
    -> View contentMsg
view shared { toContentMsg, model, content } =
    { title = content.title
    , body =
        [ viewHeader shared toContentMsg model
        , viewTranslationsApiDataMessage shared
        , div [ class "page mx-5" ] [ viewGlobalErrorMessages shared toContentMsg ]
        , div [ class "page mx-5" ] content.body
        , viewFooter shared
        ]
    }


viewHeader : Shared.Model -> (Msg -> contentMsg) -> Model -> Html contentMsg
viewHeader shared toContentMsg model =
    header []
        [ nav [ class "navbar bg-body-tertiary" ]
            [ div [ class "container-fluid" ]
                [ a [ class "navbar-brand", href "/" ]
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
                , span [ class "navbar-text" ] [ viewLoggedInText shared ]
                , div [ style "display" "flex" ]
                    [ viewLoginTimer shared toContentMsg model
                    , viewLogout shared toContentMsg
                    , select [ onInput ChangeLanguage ] (viewSelectOptions shared.locale) |> Html.map toContentMsg
                    ]
                ]
            ]
        ]


viewLoggedInText : Shared.Model -> Html contentMsg
viewLoggedInText shared =
    case shared.user of
        Just user ->
            text <| I18n.loggedInText shared.locale.t user.name

        Nothing ->
            text <| I18n.notLoggedInText shared.locale.t


viewLogout : Shared.Model -> (Msg -> contentMsg) -> Html contentMsg
viewLogout shared toContentMsg =
    case shared.user of
        Just _ ->
            let
                t =
                    shared.locale.t
            in
            h4 [ title <| I18n.logoutTooltip t, onClick Logout ] [ i [ class "bi bi-box-arrow-right me-3" ] [] ]
                |> Html.map toContentMsg

        Nothing ->
            div [ class "me-3" ] []


viewLoginTimer : Shared.Model -> (Msg -> contentMsg) -> Model -> Html contentMsg
viewLoginTimer shared toContentMsg model =
    case shared.user of
        Just _ ->
            let
                minsToExpire =
                    model.secsToExpire // 60

                timer : Html contentMsg
                timer =
                    strong [ class "me-5" ]
                        [ minsToExpire |> String.fromInt |> text ]

                fiveMinutesModal : Html contentMsg
                fiveMinutesModal =
                    viewFiveMinutesModal shared toContentMsg model

                expiredModal : Html contentMsg
                expiredModal =
                    viewExpiredModal shared toContentMsg model
            in
            div [] [ timer, fiveMinutesModal, expiredModal ]

        Nothing ->
            div [] []


viewSelectOptions : Locale -> List (Html contentMsg)
viewSelectOptions locale =
    List.map (viewSelectOption locale) Locale.languages


viewSelectOption : Locale -> Language -> Html contentMsg
viewSelectOption locale lang =
    let
        isSelected =
            locale.lang == lang

        valueString =
            Locale.toLanguageStringValue lang

        textString =
            Locale.toLanguageString locale.t lang
    in
    option [ selected isSelected, value valueString ] [ text textString ]


viewTranslationsApiDataMessage : Shared.Model -> Html contentMsg
viewTranslationsApiDataMessage shared =
    case shared.translationsApiData of
        Loading ->
            text "Loading Translations ..."

        Success _ ->
            text ""

        Failure error ->
            let
                errorText =
                    case error of
                        Http.BadUrl string ->
                            "BadUrl: " ++ string

                        Http.Timeout ->
                            "Timed out"

                        Http.NetworkError ->
                            "Network Error"

                        Http.BadStatus int ->
                            "Bad Status: " ++ String.fromInt int

                        Http.BadBody string ->
                            "Bad Body: " ++ string
            in
            div [ class "alert alert-danger" ]
                [ text "Failed to load Translations with following Error Message:"
                , br [] []
                , text errorText
                ]


viewGlobalErrorMessages : Shared.Model -> (Msg -> contentMsg) -> Html contentMsg
viewGlobalErrorMessages shared toContentMsg =
    let
        t =
            shared.locale.t
    in
    if List.isEmpty shared.globalErrors then
        div [] []

    else
        div [ class "alert alert-danger alert-dismissable show fade" ]
            [ span [] (List.map (viewGlobalErrorMessage t shared.globalErrorsTimestamp) shared.globalErrors)
            , button
                [ type_ "button"
                , class "btn-close"
                , attribute "aria-label" "Close"
                , attribute "data-bs-dismiss" "alert"
                , onClick ErrorsDismissed
                ]
                []
            ]
            |> Html.map toContentMsg


viewGlobalErrorMessage : Translations -> Time.Posix -> Error -> Html contentMsg
viewGlobalErrorMessage t time error =
    span []
        [ text (I18nError.intro t)
        , Error.toView t time error
        ]


viewFooter : Shared.Model -> Html contentMsg
viewFooter shared =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] (viewFooterLinks shared) ]
                , div [ class "col text-center" ]
                    [ span [] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]


viewFooterLinks : Shared.Model -> List (Html contentMsg)
viewFooterLinks shared =
    let
        pages =
            [ Pages.Privacy, Pages.Imprint ]

        pageToHref page =
            Pages.toPath page

        pageToText page =
            Pages.toText page shared.locale.t

        pageToListItem page =
            li [] [ a [ href <| pageToHref page ] [ button [ class "btn btn-secondary" ] [ text <| pageToText page ] ] ]
    in
    List.map pageToListItem pages


viewFiveMinutesModal : Shared.Model -> (Msg -> contentMsg) -> Model -> Html contentMsg
viewFiveMinutesModal shared toContentMsg model =
    let
        t =
            shared.locale.t

        timeString =
            let
                mins =
                    model.secsToExpire // 60

                minsString =
                    if mins < 10 then
                        "0" ++ String.fromInt mins

                    else
                        String.fromInt mins

                secs =
                    remainderBy 60 model.secsToExpire

                secsString =
                    if secs < 10 then
                        "0" ++ String.fromInt secs

                    else
                        String.fromInt secs
            in
            minsString ++ ":" ++ secsString
    in
    div [ id Effect.fiveMinutesModalId, class "modal", tabindex -1 ]
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title" ] [ text <| I18n.fiveMinutesTitle t ]
                    , button
                        [ type_ "button"
                        , class "btn-close"
                        , attribute "data-bs-dismiss" "modal"
                        , attribute "aria-label" "Close"
                        ]
                        []
                    ]
                , div [ class "modal-body" ]
                    [ p []
                        [ text <| I18n.fiveMinutesText t timeString
                        ]
                    ]
                , div [ class "modal-footer" ]
                    [ button [ type_ "button", class "btn btn-secondary", attribute "data-bs-dismiss" "modal" ]
                        [ text <| I18n.close t ]
                    , button
                        [ type_ "button"
                        , class "btn btn-secondary"
                        , attribute "data-bs-dismiss" "modal"
                        , onClick RenewSession
                        ]
                        [ text <| I18n.renew t ]
                    ]
                ]
            ]
        ]
        |> Html.map toContentMsg


viewExpiredModal : Shared.Model -> (Msg -> contentMsg) -> Model -> Html contentMsg
viewExpiredModal shared toContentMsg model =
    let
        t =
            shared.locale.t
    in
    div [ id Effect.expiredModalId, class "modal", tabindex -1 ]
        [ div [ class "modal-dialog" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title" ] [ text <| I18n.expiredModalText t ]
                    , button
                        [ type_ "button"
                        , class "btn-close"
                        , attribute "data-bs-dismiss" "modal"
                        , attribute "aria-label" "Close"
                        ]
                        []
                    ]
                , div [ class "modal-body" ]
                    [ p []
                        [ text <| I18n.expiredModalText t
                        ]
                    ]
                ]
            ]
        ]
        |> Html.map toContentMsg
