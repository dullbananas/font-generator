module Backend exposing
    ( app
    )

import Lamdera exposing
    ( ClientId
    , SessionId
    )
import Types exposing
    ( ..
    )

type alias Model =
    BackendModel

type alias Msg =
    BackendMsg

app =
    Lamdera.backend
        { init = init
        , update = update
        , subscriptions = subscriptions
        , updateFromFrontend = updateFromFrontend
        }

init : ( Model, Cmd Msg )
init =
    (
        {}
    ,
        Cmd.none
    )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        N -> (model,Cmd.none)

updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        Nf -> (model,Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
