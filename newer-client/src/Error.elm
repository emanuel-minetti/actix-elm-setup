module Error exposing (..)

import Html exposing (Html, li, p, text, ul)
import Html.Attributes exposing (class)
import Http
import I18Next exposing (Translations)
import Time
import Translations.Error as I18n


type Error
    = HttpError String Http.Error
    | ApiError String String


toView : Translations -> Time.Posix -> Error -> Html msg
toView t timestamp error =
    let
        errorMsg =
            case error of
                HttpError msg _ ->
                    I18n.errorMsg t msg

                ApiError msg _ ->
                    I18n.errorMsg t msg

        errorContent =
            case error of
                HttpError _ httpError ->
                    "HTTP Error: "
                        ++ (httpError
                                |> httpErrorToString
                                |> I18n.errorContent t
                           )

                ApiError _ apiError ->
                    "API Error: "
                        ++ (apiError
                                |> I18n.errorContent t
                           )

        errorTimestamp =
            I18n.errorTimestamp t ++ toUtcString timestamp

        errorMessage =
            p [ class "ms-5" ]
                [ ul []
                    [ li [] [ text errorMsg ]
                    , li [] [ text errorContent ]
                    , li [] [ text errorTimestamp ]
                    ]
                ]
    in
    errorMessage


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl string ->
            "BadUrl: " ++ string

        Http.Timeout ->
            "Timed out"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus int ->
            "Bad Status: " ++ String.fromInt int

        Http.BadBody string ->
            "Bad Body: " ++ string


toUtcString : Time.Posix -> String
toUtcString time =
    let
        monthString =
            case Time.toMonth Time.utc time of
                Time.Jan ->
                    "01"

                Time.Feb ->
                    "02"

                Time.Mar ->
                    "03"

                Time.Apr ->
                    "04"

                Time.May ->
                    "05"

                Time.Jun ->
                    "06"

                Time.Jul ->
                    "07"

                Time.Aug ->
                    "08"

                Time.Sep ->
                    "09"

                Time.Oct ->
                    "10"

                Time.Nov ->
                    "11"

                Time.Dec ->
                    "12"

        hourString =
            if Time.toHour Time.utc time < 10 then
                "0" ++ String.fromInt (Time.toHour Time.utc time)

            else
                String.fromInt (Time.toHour Time.utc time)

        minuteString =
            if Time.toMinute Time.utc time < 10 then
                "0" ++ String.fromInt (Time.toMinute Time.utc time)

            else
                String.fromInt (Time.toMinute Time.utc time)

        secondString =
            if Time.toSecond Time.utc time < 10 then
                "0" ++ String.fromInt (Time.toSecond Time.utc time)

            else
                String.fromInt (Time.toSecond Time.utc time)
    in
    String.fromInt (Time.toYear Time.utc time)
        ++ "-"
        ++ monthString
        ++ "-"
        ++ String.fromInt (Time.toDay Time.utc time)
        ++ "T"
        ++ hourString
        ++ ":"
        ++ minuteString
        ++ ":"
        ++ secondString
        ++ "Z"
