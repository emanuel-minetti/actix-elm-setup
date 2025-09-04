module Pages.Home_ exposing (Model, Msg, page)

import Auth
import Effect exposing (Effect)
import Html
import Layouts
import Locale
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Translations.Home as I18nHome
import View exposing (View)


page : Auth.User -> Shared.Model -> Route () -> Page Model Msg
page user shared _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view user shared
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout _ =
    Layouts.MainLayout {}



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Auth.User -> Shared.Model -> Model -> View Msg
view user shared _ =
    let
        t =
            shared.locale.t
    in
    { title = "Home"
    , body =
        [ Html.text <| I18nHome.yourPreferredLang t <| Locale.toLanguageString t shared.locale.lang
        , Html.text ("Name: " ++ user.name)
        ]
    }
