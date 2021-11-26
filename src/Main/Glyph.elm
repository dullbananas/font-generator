module Main.Glyph exposing
    ( Glyph
    , Path
    , Point
    , paths
    , init
    , view
    , viewThumbnail
    , setPoint
    , mutateFamily
    , mutate
    )

import Dict exposing (Dict)
import Html exposing (Html)
import List.Extra
import Random
import Random.Extra exposing (andMap)
import Svg exposing (Svg)
import Svg.Attributes as SvgA
import Svg.PathD as SvgPath

type Glyph
    = Glyph Internals

type alias Internals =
    { paths : List Path
    }

type alias Path =
    List Point

type alias Point =
    { x : Float
    , y : Float
    , radians : Float
    , curviness : Float
    }

paths : Glyph -> List Path
paths (Glyph glyph) =
    glyph.paths

mutateFamily : Dict Char Glyph -> Random.Generator (Dict Char Glyph)
mutateFamily glyphs =
    glyphs
    |> Dict.toList
    |> List.map
        (\(char, glyph) ->
            Random.pair
                (Random.constant char)
                (mutate glyph)
        )
    |> Random.Extra.combine
    |> Random.map Dict.fromList

mutate : Glyph -> Random.Generator Glyph
mutate (Glyph glyph) =
    glyph.paths
    |> List.map (List.map mutatePoint >> Random.Extra.combine)
    |> Random.Extra.combine
    |> Random.map (Internals >> Glyph)

mutatePoint : Point -> Random.Generator Point
mutatePoint p =
    Random.constant Point
    |> andMap (mutateFloat 1 p.x)
    |> andMap (mutateFloat 1 p.y)
    |> andMap (mutateFloat 0.1 p.radians)
    |> andMap (mutateFloat 1 p.curviness)

mutateFloat : Float -> Float -> Random.Generator Float
mutateFloat scale num =
    Random.float -scale scale
    |> Random.map ( \delta -> num + (delta^3) )

init : Glyph
init =
    Glyph
        { paths = [initPath]
        }

initPath : Path
initPath =
    -- x, y (flipped), radians, curviness
    [ Point 0 -8 (Basics.degrees 90) 4
    , Point 8 0 (Basics.degrees 180) 4
    , Point -8 0 (Basics.degrees 0) 4
    ]

view : Maybe (Char, Glyph) -> Html msg
view maybe =
    case maybe of
        Just (_, glyph) ->
            Svg.svg
                -- Width and height are 32
                -- Coorditates are from -16 to 16 starting from top-left
                [ SvgA.viewBox "-16 -16 32 32"
                , SvgA.width "32"
                ]
                [ toSvg "" glyph
                ]

        _ ->
            Html.text ""

viewThumbnail : Maybe Glyph -> Html msg
viewThumbnail maybe =
    case maybe of
        Just glyph ->
            Svg.svg
                [ SvgA.viewBox "-16 -16 32 32"
                , SvgA.width "24"
                ]
                [ toSvg "" glyph
                ]

        _ ->
            Html.text ""

setPoint : Int -> Int -> Point -> Glyph -> Glyph
setPoint pathId pointId point (Glyph glyph) =
    Glyph
        { glyph
        | paths =
            glyph.paths
            |> List.Extra.updateAt
                pathId
                (List.Extra.setAt pointId point)
        }

viewEditor : Point -> Glyph -> Html msg
viewEditor point glyph =
    Svg.svg
        [ SvgA.viewBox "-16 -16 32 32"
        , SvgA.width "128"
        ]
        [ toSvg "" glyph
        , Svg.circle
            [ SvgA.r "0.5"
            , SvgA.cx (String.fromFloat point.x)
            , SvgA.cy (String.fromFloat point.y)
            , SvgA.stroke "#CC0000"
            , SvgA.strokeWidth "0.2"
            ]
            []
        ]

toSvg : String -> Glyph -> Svg msg
toSvg transform (Glyph glyph) =
    Svg.path
        [ SvgA.transform transform
        , SvgA.fillRule "evenodd"
        , SvgA.d <| SvgPath.pathD <|
            List.concatMap pathToSegments glyph.paths
        ]
        []

pathToSegments : Path -> List SvgPath.Segment
pathToSegments path =
    case path of
        point1 :: pointN ->
            List.concat
                -- First point
                [ [SvgPath.M (point1.x, point1.y)]

                -- Points and curves in between
                , List.map pairToSegment (toPairs path)

                -- THE END
                , [SvgPath.Z]
                ]

        [] ->
            []

pairToSegment : (Point, Point) -> SvgPath.Segment
pairToSegment (thisP, nextP) =
    -- Cubic bezier curve
    SvgPath.C
        (curveControlPoint 1 thisP)
        (curveControlPoint -1 nextP)
        (nextP.x, nextP.y)

curveControlPoint : Float -> Point -> SvgPath.Point
curveControlPoint scale {curviness, radians, x, y} =
    let
        n =
            scale * curviness
    in
    -- sin and cos are swapped for unknown reason
    ( x + (n * sin radians)
    -- SVG coordinates start at the top, so subtract to go up
    , y - (n * cos radians)
    )

{-| Create a list of each pair of consecutive items.

    > toPairs [0, 1, 2]
    [(0, 1), (1, 2), (2, 0)]
-}
toPairs : List a -> List (a, a)
toPairs list =
    case list of
        x :: xs ->
            toPairsCons x x xs

        [] ->
            []

{-| In each tuple, the first item comes from the previous step

    toPairs       [0, 1, 2, 3  ]
    toPairsCons 0  0 [1, 2, 3  ] -> (0, 1)
    toPairsCons 0     1 [2, 3  ] -> (1, 2)
    toPairsCons 0        2 [3  ] -> (2, 3)
    toPairsCons 0           3 [] -> (3, 0)
-}
toPairsCons : a -> a -> List a -> List (a, a)
toPairsCons final x1 list =
    case list of
        x2 :: remaining ->
            (x1, x2) :: toPairsCons final x2 remaining

        [] ->
            (x1, final) :: []
