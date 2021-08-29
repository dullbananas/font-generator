module Main.Progress exposing
    ( Progress
    , default
    , viewAllGlyphs
    , viewCurrentGlyph
    , attemptChar
    , setStartTime
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Image
import Random
import Random.Extra
import Random.List
import Time

type alias Progress =
    { glyphs : Dict Char (Array Glyph)
    , glyphQueue : List (Int, Char)
    , startTime : Time.Posix
    , seed : Random.Seed
    }

generateDefault : Random.Generator (Random.Seed -> Progress)
generateDefault =
    let
        glyphPopulation : List Int -> Random.Generator (Array Glyph)
        glyphPopulation pixels =
            { pixels =
                pixels
                |> List.map invertPixel
            , score = 0
            , trials = 0
            }
            |> List.repeat charPopulation
            |> List.map mutateGlyph
            |> Random.Extra.sequence
            |> Random.map Array.fromList

        glyphs : Random.Generator (Dict Char (Array Glyph))
        glyphs =
            initGlyphs
            |> List.map
                (\(char, pixels) ->
                    Random.pair
                        (Random.constant char)
                        (glyphPopulation pixels)
                )
            |> Random.Extra.sequence
            |> Random.map Dict.fromList
        
        andMap = Random.Extra.andMap
    in
    Random.constant Progress
    |> andMap glyphs
    |> andMap
        (initGlyphs
        |> List.map Tuple.first
        |> generateGlyphQueue
        )
    |> andMap (Random.constant (Time.millisToPosix 0))

charPopulation : Int
charPopulation =
    8

generateGlyphQueue : List Char -> Random.Generator (List (Int, Char))
generateGlyphQueue =
    List.concatMap
        (List.repeat charPopulation
        >> List.indexedMap Tuple.pair
        )
    >> Random.List.shuffle

type alias Glyph =
    { pixels : List Int
    , score : Int
    , trials : Int
    }

mutateGlyph : Glyph -> Random.Generator Glyph
mutateGlyph glyph =
    glyph.pixels
    |> List.map
        (\pixel ->
            Random.weighted
                (32, pixel)
                [(1, invertPixel pixel)]
        )
    |> Random.Extra.sequence
    |> Random.map
        (\newPixels ->
            { pixels = newPixels
            , score = 0
            , trials = 0
            }
        )

invertPixel : Int -> Int
invertPixel =
    negate >> (+) 1

default : Progress
default =
    let
        (progress, seed) =
            Random.initialSeed 8
            |> Random.step generateDefault
    in
    progress seed

viewGlyph : Glyph -> Html msg
viewGlyph {pixels} =
    Html.img
        [ Html.Attributes.src
            (Image.fromList
                {width = 8}.width
                (pixels
                |> List.map
                    (\pixel ->
                        (pixel * 0xFFFFFF00)
                        + 0x000000FF
                    )
                )
            |> Image.toBmpUrl
            )
        , style "height" "64px"
        , style "image-rendering" "pixelated"
        ]
        []
    |> List.singleton
    |> Html.div
        [ style "border" "1px solid blue"
        , style "padding" "4px 4px"
        , style "display" "inline-block"
        ]

viewAllGlyphs : Progress -> Html msg
viewAllGlyphs =
    .glyphs
    >> Dict.values
    >> List.concatMap Array.toList
    >> List.map viewGlyph
    >> Html.div []

viewCurrentGlyph : Progress -> Html msg
viewCurrentGlyph progress =
    progress.glyphQueue
    |> List.head
    |> Maybe.andThen
        (\(index, char) ->
            progress.glyphs
            |> Dict.get char
            |> Maybe.andThen (Array.get index)
        )
    |> Maybe.map viewGlyph
    |> Maybe.withDefault (Html.text "")

attemptChar : Char -> Time.Posix -> Progress -> Progress
attemptChar charInput time progress =
    let
        timeDiff : Int
        timeDiff =
            (-)
                (Time.posixToMillis time)
                (Time.posixToMillis progress.startTime)
    in
    case progress.glyphQueue of
        (index, char) :: nextQueue ->
            case charInput == char of
                True ->
                    { progress
                    | glyphs =
                        progress.glyphs
                        |> updateGlyphStats
                            timeDiff
                            char
                            index
                    , glyphQueue =
                        nextQueue
                    }

                False ->
                    progress

        _ ->
            progress

updateGlyphStats : Int -> Char -> Int -> Dict Char (Array Glyph) -> Dict Char (Array Glyph)
updateGlyphStats timeDiff char index =
    Dict.update char
    <| Maybe.map
    <| Array.indexedMap
    <| \indexBeingChecked glyph ->
        case indexBeingChecked == index of
            True ->
                { glyph
                | score = glyph.score + timeDiff
                , trials = glyph.trials + 1
                }

            False ->
                glyph

setStartTime : Time.Posix -> Progress -> Progress
setStartTime time progress =
    { progress
    | startTime = time
    }

initGlyphs : List (Char, List Int)
initGlyphs =
    let
        g =
            Tuple.pair
    in
    [ g 'a'
        [0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,1,1,1,1,1,1,1,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,1,1,1,1,1,1,1
        ,0,0,0,0,0,0,0,1
        ,0,0,0,0,0,0,0,0
        ]
    , g 'b'
        [1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,0,0,0,0,0,0,0
        ,1,1,1,1,1,1,1,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,1,1,1,1,1,1,1
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ]
    , g 'o'
        [0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ,1,1,1,1,1,1,1,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,0,0,0,0,0,0,1
        ,1,1,1,1,1,1,1,1
        ,0,0,0,0,0,0,0,0
        ,0,0,0,0,0,0,0,0
        ]
    ]
