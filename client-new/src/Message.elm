module Message exposing (Message, Severity(..), getLoginSuccess, seen, setSeen, severity, text, title)

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
        , seen : Bool
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


seen : Message -> Bool
seen message =
    case message of
        Message record ->
            record.seen


setSeen : Message -> Message
setSeen message =
    case message of
        Message record ->
            Message { record | seen = True }


getLoginSuccess : Message
getLoginSuccess =
    Message
        { severity = Success
        , title = I18n.empty
        , text = I18n.logoffSuccess
        , seen = False
        }
