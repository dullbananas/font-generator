module Main.Glyph exposing
    ( Glyph, Path, Point
    , paths, char
    , init, mutate, addPath, addPoint, setPoint
    , Appearance, initAppearance, view
    )

import Html exposing (Html)
import List.Extra
import Main.Util as Util
import Random
import Random.Extra
import Svg exposing (Svg)
import Svg.Attributes as SvgA
import Svg.PathD as SvgPath

type Glyph
    = Glyph Internals

type alias Internals =
    { paths : List Path
    , char : Char
    }

type alias Path =
    { points : List Point
    }

type alias Point =
    { x : Float
    , y : Float
    , radians : Float
    , curviness : Float
    }

paths : Glyph -> List Path
paths (Glyph glyph) =
    glyph.paths

char : Glyph -> Char
char (Glyph glyph) =
    glyph.char

init : Char -> Glyph
init newChar =
    Glyph
        { paths = [initPath]
        , char = newChar
        }

initPath : Path
initPath =
    -- x, y (flipped), radians, curviness
    { points =
        [ Point 16 8 (Basics.degrees 90) 4
        , Point 24 16 (Basics.degrees 180) 4
        , Point 8 16 (Basics.degrees 0) 4
        ]
    }

initPoint : Point
initPoint =
    { x = 0
    , y = 0
    , radians = 0
    , curviness = 1
    }

mutate : Glyph -> Random.Generator Glyph
mutate (Glyph glyph) =
    let
        await =
            Util.awaitGenerator
    in
    await (glyph.paths |> Random.Extra.traverse mutatePath) <| \newPaths ->
    Random.constant
        ( Glyph
            { glyph
            | paths = newPaths
            }
        )

addPath : Glyph -> Glyph
addPath (Glyph glyph) =
    ( Glyph
        { glyph
        | paths = glyph.paths ++ [ initPath ]
        }
    )

addPoint : Int -> Glyph -> Glyph
addPoint pathId (Glyph glyph) =
    ( Glyph
        { glyph
        | paths =
            glyph.paths
            |> List.Extra.updateAt
                pathId
                (\path ->
                    { path
                    | points = path.points ++ [ initPoint ]
                    }
                )
        }
    )

mutatePath : Path -> Random.Generator Path
mutatePath path =
    let
        await =
            Util.awaitGenerator
    in
    await (path.points |> Random.Extra.traverse mutatePoint) <| \newPoints ->
    Random.constant
        { points = newPoints
        }

mutatePoint : Point -> Random.Generator Point
mutatePoint point =
    let
        await =
            Util.awaitGenerator
    in
    await (mutateFloat 0.5 point.x) <| \x ->
    await (mutateFloat 0.5 point.y) <| \y ->
    await (mutateFloat 0.1 point.radians) <| \radians ->
    await (mutateFloat 1 point.curviness) <| \curviness ->
    Random.constant
        { x = x
        , y = y
        , radians = radians
        , curviness = curviness
        }

mutateFloat : Float -> Float -> Random.Generator Float
mutateFloat scale num =
    Random.float -scale scale
    |> Random.map ( \delta -> num + (delta^3) )

setPoint : Int -> Int -> Point -> Glyph -> Glyph
setPoint pathId pointId point (Glyph glyph) =
    Glyph
        { glyph
        | paths =
            glyph.paths
            |> List.Extra.updateAt
                pathId
                (\path ->
                    { path
                    | points =
                        path.points
                        |> List.Extra.setAt pointId point
                    }
                )
        }

type alias Appearance =
    { height : Float
    , grid : Bool
    }

initAppearance : Appearance
initAppearance =
    { height = 32
    , grid = False
    }

view : Appearance -> Maybe Glyph -> Html msg
view appearance maybeGlyph =
    case maybeGlyph of
        Just (Glyph glyph) ->
            Svg.svg
                [ SvgA.viewBox "0 0 32 32"
                    -- Coordinates start from the top-left at (0, 0)
                    -- Width and height of the coordinate space is 32
                , SvgA.height (String.fromFloat appearance.height)
                    -- Scale to appearance.height
                ]
                [ case appearance.grid of
                    True ->
                        Svg.g
                            [ SvgA.stroke "#cccccc"
                            , SvgA.strokeWidth "0.1"
                            ]
                            (List.concat
                                [ gridLines
                                    (\n ->
                                        ( ( n, 0 )
                                        , ( n, 32 )
                                        )
                                    )
                                , gridLines
                                    (\n ->
                                        ( ( 0, n )
                                        , ( 32, n )
                                        )
                                    )
                                ]
                            )

                    False ->
                        Html.text ""
                , Svg.path
                    [ SvgA.d <| SvgPath.pathD <|
                        List.concatMap pathToSegments glyph.paths
                    , SvgA.fillRule "evenodd"
                    ]
                    []
                ]

        Nothing ->
            Html.text ""

gridLines : (Int -> ((Int, Int), (Int, Int))) -> List (Svg msg)
gridLines stepToPoints =
    List.range 0 8
    |> List.map
        (\step ->
            let
                ((x1, y1), (x2, y2)) =
                    stepToPoints (step * 4)
            in
                Svg.line
                    [ SvgA.x1 (String.fromInt x1)
                    , SvgA.y1 (String.fromInt y1)
                    , SvgA.x2 (String.fromInt x2)
                    , SvgA.y2 (String.fromInt y2)
                    ]
                    []
        )

pathToSegments : Path -> List SvgPath.Segment
pathToSegments path =
    case path.points of
        point1 :: pointN ->
            List.concat
                -- First point
                [ [SvgPath.M (point1.x, point1.y)]

                -- Points and curves in between
                , List.map pairToSegment (toPairs path.points)

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
    -- sin and cos are swapped to change the direction
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
