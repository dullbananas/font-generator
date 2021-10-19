module Types exposing
    ( ..
    )

import Main.Progress as Progress exposing
    ( Progress
    )
import Time

type alias FrontendModel =
    { progress : Progress
    , startTime : Time.Posix
    }

type alias BackendModel =
    {}

type FrontendMsg
    = DoNothing
    | InitSeed Time.Posix
    | TextFieldInput String
    | AttemptChar Char Time.Posix
    | TextFieldFocus
    | SetStartTime Time.Posix
    | Frame Time.Posix

type ToBackend
    = Nf

type BackendMsg
    = N

type ToFrontend
    = Nb
