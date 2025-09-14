module Error exposing (..)

import Http


type Error
    = HttpError Http.Error
    | ApiError String
