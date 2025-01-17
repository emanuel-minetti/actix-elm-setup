module Page.Login exposing (Model, Msg(..), init, setSession, toSession, update, view)

import ApiResponse exposing (ApiResponse, apiResponseDecoder)
import Html exposing (Html, br, button, div, form, h1, input, label, text)
import Html.Attributes exposing (autofocus, class, for, id, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Route exposing (Route)
import ServerRequest
import Session exposing (Session)
import Translations.Login as I18n
import User


type alias Model =
    { session : Session
    , redirect : Route
    , username : String
    , password : String
    }


type Msg
    = Username String
    | Password String
    | LoginRequested
    | GotLoginResponse (Result Http.Error ApiResponse)
    | UserMsg User.Msg


init : Session -> Route -> ( Model, Cmd Msg )
init session route =
    let
        newModel =
            Model session route "" ""
    in
    ( newModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username username ->
            ( { model | username = username }, Cmd.none )

        Password password ->
            ( { model | password = password }, Cmd.none )

        LoginRequested ->
            ( model, loadLogin model )

        GotLoginResponse result ->
            case result of
                Ok apiResponse ->
                    case apiResponse.data of
                        ApiResponse.LoginResponseData serverLoginData ->
                            let
                                newUser =
                                    User.setToken serverLoginData.token <| Session.user model.session

                                newSession =
                                    Session.setUser newUser model.session

                                --get session from server
                                token =
                                    newSession
                                        |> Session.user
                                        |> User.token

                                userCmd =
                                    User.loadSession token

                                cmd =
                                    Cmd.batch [ Cmd.map UserMsg userCmd ]
                            in
                            ( { model | session = newSession }, cmd )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        UserMsg usrMsg ->
            case usrMsg of
                _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        t =
            (Session.locale model.session).t
    in
    div [ class "container" ]
        [ h1 []
            [ text <| I18n.title t ]
        , br [] []
        , text <| I18n.message t
        , br [] []
        , form []
            [ div [ class "mb-3" ]
                [ label [ class "form-label", for "usernameInput" ] [ text <| I18n.username t ]
                , input
                    [ id "usernameInput"
                    , type_ "text"
                    , class "form-control"
                    , value model.username
                    , onInput Username
                    , tabindex 1
                    , autofocus True
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
                    , onInput Password
                    , tabindex 2
                    ]
                    []
                ]
            , button [ type_ "button", class "btn btn-primary", onClick LoginRequested, tabindex 3 ] [ text <| I18n.title t ]
            ]
        ]


toSession : Model -> Session
toSession model =
    model.session


setSession : Session -> Model -> Model
setSession session model =
    { model | session = session }


loadLogin : Model -> Cmd Msg
loadLogin model =
    ServerRequest.login model.username model.password <| Http.expectJson GotLoginResponse apiResponseDecoder
