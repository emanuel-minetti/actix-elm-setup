module Page.Privacy exposing (Model, Msg, init, update, view)

import Html exposing (Html, h3, text)
import I18n exposing (I18n)


type alias Model =
    { i18n : I18n }


type Msg
    = FetchingTranslations
    | GotTranslations


init : I18n -> ( Model, Cmd Msg )
init i18n =
    ( { i18n = i18n }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    h3 [] [ text "You made it to the privacy declaration" ]
