module Layouts.MainLayout exposing (Model, Msg(..), Props, layout)

import Api exposing (Data(..))
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (Error(..))
import Layout exposing (Layout)
import Pages
import Route exposing (Route)
import Shared
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
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view shared { toContentMsg, model, content } =
    { title = content.title
    , body =
        [ text "MainLayout"
        , br [] []
        , translationsApiDataMessage shared
        , div [ class "page" ] content.body
        , viewFooter shared
        ]
    }


translationsApiDataMessage : Shared.Model -> Html contentMsg
translationsApiDataMessage shared =
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
