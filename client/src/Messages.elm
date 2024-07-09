module Messages exposing (Messages, addInfo, buildErrorMessage, removeFirstInfo, viewMessages)

import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class, id)
import Http
import I18n exposing (I18n)


type alias Messages =
    { infos : List String
    , errors : List String
    }


removeFirstInfo : Messages -> Messages
removeFirstInfo messages =
    { messages | infos = Maybe.withDefault [] (List.tail messages.infos) }


addInfo : Messages -> String -> Messages
addInfo messages info =
    { messages | infos = info :: messages.infos }


viewMessages : Messages -> Html msg
viewMessages messages =
    div [ id "messages" ]
        [ viewInfos messages
        , viewErrors messages
        ]


viewInfos : Messages -> Html msg
viewInfos messages =
    let
        viewEntry message =
            li [] [ text message ]
    in
    if List.length messages.infos == 0 then
        text ""

    else if List.length messages.infos > 1 then
        ul [ class "text-center alert alert-light" ] (List.map viewEntry messages.infos)

    else
        div [ class "text-center alert alert-light" ] [ text (Maybe.withDefault "" (List.head messages.infos)) ]


viewErrors : Messages -> Html msg
viewErrors messages =
    let
        viewEntry message =
            li [] [ text message ]
    in
    if List.length messages.errors == 0 then
        text ""

    else if List.length messages.errors > 1 then
        ul [ class "text-center alert alert-danger" ] (List.map viewEntry messages.errors)

    else
        div [ class "text-center alert alert-danger" ] [ text (Maybe.withDefault "" (List.head messages.errors)) ]


buildErrorMessage : Http.Error -> I18n -> String
buildErrorMessage httpError i18n =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            I18n.timeout i18n

        Http.NetworkError ->
            I18n.network i18n

        Http.BadStatus statusCode ->
            I18n.badStatus i18n ++ String.fromInt statusCode

        Http.BadBody message ->
            message
