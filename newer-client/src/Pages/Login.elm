module Pages.Login exposing (Model, Msg, page)

import Api exposing (ApiResponseData(..))
import Api.Login
import Api.Session
import Api.Session.Model
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Translations.Login as I18n
import User
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update shared
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
    , errorMessage : String
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { username = ""
      , password = ""
      , isSubmittingForm = False
      , errorMessage = ""
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
    | LoginApiResponded (Result Http.Error (Api.ApiResponse Api.Login.Model))
    | SessionApiResponded String (Result Http.Error (Api.ApiResponse Api.Session.Model))


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
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
            ( { model | isSubmittingForm = True, errorMessage = "" }
            , Api.Login.post { onResponse = LoginApiResponded, user = model.username, password = model.password }
            )

        LoginApiResponded (Ok apiResponseData) ->
            let
                hasError =
                    not <| String.isEmpty apiResponseData.error
            in
            case hasError of
                True ->
                    let
                        message =
                            I18n.fail shared.locale.t
                    in
                    ( { model | errorMessage = message, isSubmittingForm = False }, Effect.none )

                False ->
                    let
                        token =
                            case apiResponseData.data of
                                Api.ResponseData loginData ->
                                    loginData.token

                                Api.NoneResponseData _ ->
                                    ""

                        --Api.Login.Model.LoginResponseData loginApiResponseData ->
                        --    loginApiResponseData.token
                        --
                        --Api.Login.Model.NoneResponseData _ ->
                        --    ""
                    in
                    ( model
                    , Api.Session.get { token = token, onResponse = SessionApiResponded token }
                    )

        LoginApiResponded (Err error) ->
            let
                httpError =
                    httpErrorToString error

                message =
                    I18n.networkError shared.locale.t ++ httpError
            in
            ( { model | isSubmittingForm = False, errorMessage = message }
            , Effect.none
            )

        SessionApiResponded token (Ok apiResponseData) ->
            let
                hasError =
                    not <| String.isEmpty apiResponseData.error
            in
            case hasError of
                True ->
                    let
                        message =
                            I18n.fail shared.locale.t
                    in
                    ( { model | errorMessage = message, isSubmittingForm = False }, Effect.none )

                False ->
                    case apiResponseData.data of
                        ResponseData sessionData ->
                            ( { model | errorMessage = "", isSubmittingForm = False }
                            , Effect.login
                                { token = token
                                , expires = apiResponseData.expires
                                , name = sessionData.name
                                , preferredLang = sessionData.lang
                                }
                            )

                        NoneResponseData _ ->
                            ( { model | errorMessage = "", isSubmittingForm = False }, Effect.none )

        SessionApiResponded _ (Err error) ->
            let
                httpError =
                    httpErrorToString error

                message =
                    I18n.networkError shared.locale.t ++ httpError
            in
            ( { model | isSubmittingForm = False, errorMessage = message }
            , Effect.none
            )


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl string ->
            "BadUrl: " ++ string

        Http.Timeout ->
            "Timed Out"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus int ->
            "Bad Status: " ++ String.fromInt int

        Http.BadBody string ->
            "Bad Body: " ++ string



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
                , viewErrorMessage model
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


viewErrorMessage : Model -> Html Msg
viewErrorMessage model =
    case String.isEmpty model.errorMessage of
        True ->
            div [] []

        False ->
            div [ class "alert alert-danger", attribute "role" "alert" ] [ text model.errorMessage ]


viewButton : Shared.Model -> Model -> Html Msg
viewButton shared model =
    let
        t =
            shared.locale.t
    in
    case model.isSubmittingForm of
        True ->
            button [ type_ "submit", class "btn btn-primary", tabindex 3, disabled True ]
                [ div [ class "spinner-border", attribute "role" "status" ]
                    [ span [ class "visually-hidden" ] [ text <| I18n.loggingIn t ]
                    ]
                ]

        False ->
            button [ type_ "submit", class "btn btn-primary", tabindex 3 ] [ text <| I18n.login t ]
