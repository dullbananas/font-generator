module Main.Progress exposing
    ( Progress
    , init
    , empty
    , viewAllGlyphs
    , viewCurrentGlyph
    , attemptChar
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

populationSize : Int
populationSize =
    8

invertPixel : Int -> Int
invertPixel =
    negate >> (+) 1

rounds : Int
rounds =
    1

type alias Progress =
    { glyphs : Dict Char (Array Glyph)
    , glyphQueue : List (Int, Char)
    , seed : Random.Seed
    }

type alias Glyph =
    { pixels : List Int
    , score : Int
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
            }
            |> List.repeat populationSize
            |> List.map mutateGlyph
            |> Random.Extra.sequence
            |> Random.map Array.fromList

        glyphs : Random.Generator (Dict Char (Array Glyph))
        glyphs =
            defaultPixels
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
    |> andMap generateGlyphQueue

generateGlyphQueue : Random.Generator (List (Int, Char))
generateGlyphQueue =
    defaultPixels
    |> List.map Tuple.first
    |> List.concatMap
        (List.repeat populationSize
        >> List.indexedMap Tuple.pair
        )
    |> Random.List.shuffle
    |> Random.list rounds
    |> Random.map List.concat

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
            }
        )

init : Time.Posix -> Progress
init time =
    let
        (progress, seed) =
            time
            |> Time.posixToMillis
            |> Random.initialSeed
            |> Random.step generateDefault
    in
    progress seed

empty : Progress
empty =
    { glyphs = Dict.empty
    , glyphQueue = []
    , seed = Random.initialSeed 0
    }

viewGlyph : Glyph -> Html msg
viewGlyph glyph =
    Html.div
        [ style "border" "1px solid blue"
        , style "padding" "4px 4px"
        , style "display" "inline-block"
        ]
        [ Html.img
            [ Html.Attributes.src
                (Image.fromList
                    {width = 8}.width
                    (glyph.pixels
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
        , Html.br [] []
        , Html.text (String.fromInt glyph.score)
        ]

viewAllGlyphs : Progress -> Html msg
viewAllGlyphs =
    .glyphs
    >> Dict.values
    >> List.concatMap Array.toList
    >> List.sortBy .score
    >> List.map viewGlyph
    >> Html.div []

viewCurrentGlyph : Progress -> Html msg
viewCurrentGlyph progress =
    progress.glyphQueue
    |> List.head
    |> Maybe.andThen
        (\(index, char) ->
            Just progress.glyphs
            |> Maybe.andThen (Dict.get char)
            |> Maybe.andThen (Array.get index)
        )
    |> Maybe.map viewGlyph
    |> Maybe.withDefault (Html.text "")

attemptChar : Char -> Int -> Progress -> Maybe Progress
attemptChar charInput timeDiff progress =
    case progress.glyphQueue of
        (index, char) :: nextQueue ->
            case (==) charInput char of
                True ->
                    Just
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
                    Nothing

        _ ->
            Nothing

updateGlyphStats : Int -> Char -> Int -> Dict Char (Array Glyph) -> Dict Char (Array Glyph)
updateGlyphStats timeDiff char index =
    Dict.update char
    <| Maybe.map
    <| Array.indexedMap
    <| \itemIndex glyph ->
        { glyph
        | score =
            case (==) itemIndex index of
                True ->
                    glyph.score + timeDiff

                False ->
                    glyph.score
        }

defaultPixels : List (Char, List Int)
defaultPixels =
    let
        -- glyph
        g : Char -> List (List { pixel : Int }) -> (Char, List Int)
        g key pixels =
            (key, (List.concat >> List.map .pixel) pixels)

        -- repeat
        r : Int -> a -> List a
        r =
            List.repeat
        
        rconcat : Int -> List (List a) -> List a
        rconcat count =
            List.repeat count >> List.concatMap List.concat
        
        row : Int
        row =
            8

        blank : { pixel : Int }
        blank =
            { pixel = 0 }

        filled : { pixel : Int }
        filled =
            { pixel = 1 }
        
        fillSides : Int -> List { pixel : Int }
        fillSides count =
            rconcat count
                [ [filled]
                , r (row - 2) blank
                , [filled]
                ]
    in
    [ g 'a'
        [ r (row * 7) blank
        , r row filled
        , rconcat 5
            [ [filled]
            , r (row - 2) blank
            , [filled]
            ]
        , r row filled
        , r (row - 1) blank
        , [filled]
        , r row blank
        ]
    , g 'b'
        [ rconcat 7
            [ [filled]
            , r (row - 1) blank
            ]
        , r row filled
        , rconcat 5
            [ [filled]
            , r (row - 2) blank
            , [filled]
            ]
        , r row filled
        , r (row * 2) blank
        ]
    , g 'o'
        [ r (row * 7) blank
        , r row filled
        , rconcat 5
            [ [filled]
            , r (row - 2) blank
            , [filled]
            ]
        , r row filled
        , r (row * 2) blank
        ]
    ]
