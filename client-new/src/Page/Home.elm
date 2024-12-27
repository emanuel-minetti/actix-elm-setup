module Page.Home exposing (Model, Msg(..), init, setSession, toSession, view)

import Html exposing (Html, br, div, h1, text)
import Html.Attributes exposing (class)
import Locale
import Session exposing (Session)
import Translations.Home as I18n


type Msg
    = NotLoggedIn
    | None


type alias Model =
    { session : Session }


init : Session -> ( Model, Cmd Msg )
init session =
    ( Model session, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        locale =
            Session.locale model.session
    in
    div [ class "container" ]
        [ h1 []
            [ text <| I18n.title locale.t ]
        , br [] []
        , text <| I18n.yourPreferredLang locale.t <| Locale.toValue <| locale
        ]


toSession : Model -> Session
toSession model =
    model.session


setSession : Session -> Model -> Model
setSession session model =
    { model | session = session }
