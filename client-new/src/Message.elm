module Message exposing (Message, Severity(..), getLoginSuccess, severity, text, title)

import I18Next exposing (Translations)
import Translations.Message as I18n


type Severity
    = Success
    | Info
    | Warning
    | Error


type Message
    = Message
        { severity : Severity
        , title : Translations -> String
        , text : Translations -> String
        }


severity : Message -> Severity
severity message =
    case message of
        Message record ->
            record.severity


title : Message -> Translations -> String
title message =
    case message of
        Message record ->
            record.title


text : Message -> Translations -> String
text message =
    case message of
        Message record ->
            record.text


getLoginSuccess : Message
getLoginSuccess =
    Message
        { severity = Success
        , title = I18n.empty
        , text = I18n.logoffSuccess
        }
