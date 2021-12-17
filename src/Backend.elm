module Backend exposing
    ( app
    )

import Bridge exposing (ToBackend(..))
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Main.Glyph as Glyph exposing (Glyph)
import Main.Page.NewGlyphs as NewGlyphs
import Main.Page.Test as Test
import Main.Progress as Progress exposing (Progress)
import Random
import Types exposing (BackendMsg(..), ToFrontend(..), FrontendMsg(..))

type alias Model =
    Types.BackendModel

type alias Msg =
    Types.BackendMsg

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
        NewGlyphsRequest ->
            ( model
            , case Dict.get sessionId model.newGlyphs of
                Just glyphs ->
                    Lamdera.sendToFrontend clientId
                        <| ToFrontend
                        <| NewGlyphsMsg
                        <| NewGlyphs.GlyphsRestore glyphs

                Nothing ->
                    Cmd.none
            )

        NewGlyphSave glyph ->
            Tuple.pair
                { model
                | newGlyphs =
                    model.newGlyphs
                    |> Dict.update sessionId
                        (\dict ->
                            dict
                            |> Maybe.withDefault Dict.empty
                            |> Dict.insert (Glyph.char glyph) glyph
                            |> Just
                        )
                }
                Cmd.none

        ProgressAdd glyphsDict ->
            let
                calcNewId counter =
                    case Dict.member counter model.progress of
                        True ->
                            calcNewId (counter + 1)

                        False ->
                            counter

                newId =
                    calcNewId (Dict.size model.progress)

                generateProgress =
                    Progress.init (Dict.values glyphsDict)

                (progress, seed) =
                    model.seed
                    |> Random.step generateProgress
            in
            (
                { model

                | progress =
                    model.progress
                    |> Dict.insert newId progress

                , seed =
                    seed
                }
            ,
                Lamdera.sendToFrontend clientId
                    <| ToFrontend
                    <| TestRedirect newId
            )

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
                        Lamdera.sendToFrontend clientId
                            <| ToFrontend
                            <| TestMsg
                            <| Test.GlyphChange glyph

                    Nothing ->
                        Cmd.none
                )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
