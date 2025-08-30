module Pages.Login exposing (Model, Msg, page)

import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Translations.Login as I18n
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout _ =
    Layouts.MainLayout {}



-- INIT


type alias Model =
    { username : String
    , password : String
    , isSubmittingForm : Bool
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { username = ""
      , password = ""
      , isSubmittingForm = False
      }
    , Effect.none
    )



-- UPDATE


type Field
    = User
    | Password


type Msg
    = UserUpdatedInput Field String
    | UserSubmittedForm


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UserUpdatedInput User userName ->
            ( { model | username = userName }
            , Effect.none
            )

        UserUpdatedInput Password pw ->
            ( { model | password = pw }
            , Effect.none
            )

        UserSubmittedForm ->
            ( { model | isSubmittingForm = True }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        t =
            shared.locale.t
    in
    { title = I18n.title t
    , body =
        [ div []
            [ div [ class "container" ]
                [ h1 []
                    [ text <| I18n.title t ]
                , br [] []
                , text <| I18n.message t
                , br [] []
                , Html.form [ onSubmit UserSubmittedForm ]
                    [ div [ class "mb-3" ]
                        [ label [ class "form-label", for "usernameInput" ] [ text <| I18n.username t ]
                        , input
                            [ id "usernameInput"
                            , type_ "text"
                            , class "form-control"
                            , value model.username
                            , tabindex 1
                            , autofocus True
                            , onInput (UserUpdatedInput User)
                            ]
                            []
                        ]
                    , div [ class "mb-3" ]
                        [ label [ class "form-label", for "passwordInput" ] [ text <| I18n.password t ]
                        , input
                            [ id "passwordInput"
                            , type_ "password"
                            , class "form-control"
                            , value model.password
                            , tabindex 2
                            , onInput (UserUpdatedInput Password)
                            ]
                            []
                        ]
                    , viewButton shared model
                    ]
                ]
            ]
        ]
    }


viewButton : Shared.Model -> Model -> Html Msg
viewButton shared model =
    let
        t =
            shared.locale.t
    in
    case model.isSubmittingForm of
        True ->
            button [ type_ "submit", class "btn btn-primary", tabindex 3, disabled True ]
                [ div [ class "spinner-border" ] [ span [ class "visually-hidden" ] [ text <| I18n.loggingIn t ] ] ]

        False ->
            button [ type_ "submit", class "btn btn-primary", tabindex 3 ] [ text <| I18n.login t ]
