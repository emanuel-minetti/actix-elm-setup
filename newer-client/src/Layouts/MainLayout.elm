module Layouts.MainLayout exposing (Model, Msg(..), Props, layout)

import Api exposing (Data(..))
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Layout exposing (Layout)
import Locale exposing (Language, Locale)
import Pages
import Route exposing (Route)
import Shared
import Translations.Page as I18n
import View exposing (View)


type alias Props =
    {}


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout _ shared _ =
    Layout.new
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )



-- UPDATE


type Msg
    = Logout
    | ChangeLanguage String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view shared { toContentMsg, model, content } =
    { title = content.title
    , body =
        [ viewHeader shared toContentMsg
        , viewTranslationsApiDataMessage shared
        , div [ class "page ms-5" ] content.body
        , viewFooter shared
        ]
    }


viewHeader : Shared.Model -> (Msg -> contentMsg) -> Html contentMsg
viewHeader shared toContentMsg =
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
                    [ viewLoginTimer shared
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


viewLoginTimer : Shared.Model -> Html contentMsg
viewLoginTimer _ =
    -- TODO adjust if session timeout is known
    h4 [] [ text "30" ]


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
                        BadUrl string ->
                            "BadUrl: " ++ string

                        Timeout ->
                            "Timed out"

                        NetworkError ->
                            "Network Error"

                        BadStatus int ->
                            "Bad Status: " ++ String.fromInt int

                        BadBody string ->
                            "Bad Body: " ++ string
            in
            div [ class "alert alert-danger" ]
                [ text "Failed to load Translations with following Error Message:"
                , br [] []
                , text errorText
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
