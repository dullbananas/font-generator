module Backend exposing
    ( app
    )

import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Main.Progress as Progress exposing (Progress)
import Random
import Types exposing (..)

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
    Tuple.pair
        { progress = Dict.empty
        , newGlyphs = Dict.empty
        , seed = Random.initialSeed 0
        }
        Cmd.none

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        N -> (model,Cmd.none)

updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NewGlyphsSave newItems ->
            Tuple.pair
                { model
                | newGlyphs =
                    model.newGlyphs
                    |> Dict.update sessionId
                        (\dict ->
                            dict
                            |> Maybe.withDefault Dict.empty
                            |> Dict.union newItems
                            |> Just
                        )
                }
                Cmd.none

        GlyphRequest id maybeTime ->
            let
                submitTime =
                    case maybeTime of
                        Nothing ->
                            identity

                        Just time ->
                            Progress.submitTime clientId time

                generateProgress =
                    case
                        model.progress
                        |> Dict.get id
                    of
                        Nothing ->
                            Random.constant Nothing

                        Just oldProgress ->
                            oldProgress
                            |> submitTime
                            |> Progress.nextGlyph clientId
                            |> Random.map Just

                (progress, seed) =
                    model.seed
                    |> Random.step generateProgress
            in
            Tuple.pair
                { model

                | progress =
                    model.progress
                    |> Dict.update id (always progress)

                , seed =
                    seed
                }
                ( case
                    progress
                    |> Maybe.andThen (Progress.getCurrentGlyph clientId)
                of
                    Just glyph ->
                        Lamdera.sendToFrontend clientId (GlyphChange glyph)

                    Nothing ->
                        Cmd.none
                )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
