module Main.Progress exposing
    ( Progress
    , init, submitTime, nextGlyph
    , getCurrentGlyph
    )

import Dict exposing (Dict)
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
import Main.Util as Util
import Random
import Random.Extra
import Random.List
import Time

type Progress
    = Progress Internals

type alias Internals =
    { parentHistory : List Parent
    , nextParent : Parent
    , remainingGlyphs : List Glyph
    , currentGlyphs : Dict Lamdera.ClientId Glyph
    , name : String
    }

type alias Parent =
    { glyphs : Dict Char Glyph
    , scores : Dict Char Float
    }

parentSubmitTime : Glyph -> Float -> Parent -> Parent
parentSubmitTime glyph time parent =
    let
        char =
            Glyph.char glyph

        changedParent =
            { parent

            | glyphs =
                parent.glyphs
                |> Dict.insert char glyph

            , scores =
                parent.scores
                |> Dict.insert char time
            }
    in
    case
        parent.scores
        |> Dict.get char
    of
        Nothing ->
            changedParent

        Just oldTime ->
            if time < oldTime
                then changedParent
                else parent

submitTime : Lamdera.ClientId -> Float -> Progress -> Progress
submitTime clientId time (Progress progress) =
    Progress <|
    case
        progress.currentGlyphs
        |> Dict.get clientId
    of
        Nothing ->
            progress

        Just glyph ->
            { progress

            | nextParent =
                progress.nextParent
                |> parentSubmitTime glyph time

            , currentGlyphs =
                progress.currentGlyphs
                |> Dict.remove clientId
            }

nextGlyph : Lamdera.ClientId -> Progress -> Random.Generator Progress
nextGlyph clientId (Progress progress) =
    ( case progress.remainingGlyphs of
        _ :: _ ->
            Random.pair
                (Random.constant progress.remainingGlyphs)
                (Random.constant identity)

        [] ->
            Random.pair
                (mutateParent progress.nextParent)
                (Random.constant ((::) progress.nextParent))
    )
    |> Random.map
        (\(glyphs, updateParentHistory) ->
            case glyphs of
                glyph :: listGlyph ->
                    { progress

                    | parentHistory =
                        progress.parentHistory
                        |> updateParentHistory

                    , remainingGlyphs =
                        listGlyph

                    , currentGlyphs =
                        progress.currentGlyphs
                        |> Dict.insert clientId glyph
                    }

                [] ->
                    progress
        )
    |> Random.map Progress

init : List Glyph -> Random.Generator Progress
init glyphs =
    let
        parent =
            { glyphs =
                glyphs
                |> List.map (\glyph -> (Glyph.char glyph, glyph))
                |> Dict.fromList
            , scores =
                Dict.empty
            }

        await =
            Util.awaitGenerator
    in
    await (mutateParent parent) <| \remainingGlyphs ->
    Random.constant
        ( Progress
            { parentHistory = []
            , nextParent = parent
            , remainingGlyphs = remainingGlyphs
            , currentGlyphs = Dict.empty
            , name = ""
            }
        )

getCurrentGlyph : Lamdera.ClientId -> Progress -> Maybe Glyph
getCurrentGlyph clientId (Progress progress) =
    progress.currentGlyphs
    |> Dict.get clientId

mutateParent : Parent -> Random.Generator (List Glyph)
mutateParent parent =
    parent.glyphs
    |> Dict.values
    |> Random.Extra.traverse Glyph.mutate
    |> Random.andThen Random.List.shuffle
