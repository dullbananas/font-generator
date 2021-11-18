module Main.Progress exposing
    ( Progress
    , init
    , getCurrentGlyph
    , submitTime
    , nextGlyph
    )

import Dict exposing (Dict)
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
import Random
import Random.Extra exposing (andMap)
import Random.List
import Time

type alias Progress =
    { parentHistory : List Parent
    , nextParent : Parent
    , remainingGlyphs : List (Char, Glyph)
    , currentGlyphs : Dict Lamdera.ClientId (Char, Glyph)
    , name : String
    }

type alias Parent =
    { glyphs : Glyph.Family
    , scores : Dict Char Float
    }

parentSubmitTime : (Char, Glyph) -> Float -> Parent -> Parent
parentSubmitTime (char, glyph) time parent =
    let
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
submitTime clientId time progress =
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
nextGlyph clientId progress =
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

init : Glyph.Family -> Random.Generator Progress
init glyphs =
    let
        parent =
            { glyphs = glyphs
            , scores = Dict.empty
            }
    in
    Random.constant Progress
    |> andMap (Random.constant [])
    |> andMap (Random.constant parent)
    |> andMap (mutateParent parent)
    |> andMap (Random.constant Dict.empty)
    |> andMap (Random.constant "")

getCurrentGlyph : Lamdera.ClientId -> Progress -> Maybe (Char, Glyph)
getCurrentGlyph clientId progress =
    progress.currentGlyphs
    |> Dict.get clientId

mutateParent : Parent -> Random.Generator (List (Char, Glyph))
mutateParent parent =
    parent.glyphs
    |> Glyph.mutateFamily
    |> Random.map Dict.toList
    |> Random.andThen Random.List.shuffle
