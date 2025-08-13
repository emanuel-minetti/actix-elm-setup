module Layouts.MainLayout exposing (Model, Msg, Props, layout)

import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Layout exposing (Layout)
import Pages
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Props =
    {}


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout _ _ _ =
    Layout.new
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view { toContentMsg, model, content } =
    { title = content.title
    , body =
        [ text "MainLayout"
        , div [ class "page" ] content.body
        , viewFooter model
        ]
    }


viewFooter : Model -> Html contentMsg
viewFooter _ =
    footer [ class "bg-body-tertiary" ]
        [ div [ class "container-fluid" ]
            [ div [ class "row align-items-start" ]
                [ div [ class "col" ]
                    [ ul [ class "list-unstyled" ] viewFooterLinks ]
                , div [ class "col text-center" ]
                    [ span [] [ text "Version: 0.0.0" ] ]
                , div [ class "col" ]
                    [ span [ class "float-end" ] [ text "© Example.com 2024" ] ]
                ]
            ]
        ]


viewFooterLinks : List (Html contentMsg)
viewFooterLinks =
    let
        pages =
            [ Pages.Privacy, Pages.Imprint ]

        routeToItem page =
            li [] [ a [ href <| Pages.toPath page ] [ button [ class "btn btn-secondary" ] [ text <| Pages.toText page ] ] ]
    in
    List.map routeToItem pages
