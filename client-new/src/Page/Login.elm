module Page.Login exposing (Model, Msg(..), init, setSession, toSession, view)

import Html exposing (Html, br, div, h1, text)
import Html.Attributes exposing (class)
import Route exposing (Route)
import Session exposing (Session)
import Translations.Login as I18n


type alias Model =
    { session : Session
    , redirect : Route
    }


type Msg
    = None


init : Session -> Route -> ( Model, Cmd Msg )
init session route =
    let
        newModel =
            Model session route

        _ =
            Debug.log "loginModel" newModel
    in
    ( newModel, Cmd.none )


view : Model -> Html msg
view model =
    let
        locale =
            Session.locale model.session
    in
    div [ class "container" ]
        [ h1 []
            [ text <| I18n.title locale.t ]
        , br [] []
        , text <| I18n.message locale.t
        ]


toSession : Model -> Session
toSession model =
    model.session


setSession : Session -> Model -> Model
setSession session model =
    { model | session = session }
