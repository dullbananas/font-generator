module Main.Page.NewGlyphs exposing
    ( Model, init, view
    , Msg(..), update
    )

import Bridge exposing (ToBackend(..))
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attribute
import Html.Events as Event
import Html.Lazy
import Lamdera
import Main.Glyph as Glyph exposing (Glyph, initAppearance)

type alias Model =
    { glyphs : Dict Char Glyph
    , newChar : Maybe Char
    }

type Msg
    = NewCharChange String
    | NewCharSubmit
    | PathAdd Char
    | PointAdd Char Int
    | PointChange Char Int Int Glyph.Point
    | EditFinish
    | GlyphsRestore (Dict Char Glyph)

init : Model
init =
    { glyphs = Dict.empty
    , newChar = Nothing
    }

view : Char -> Model -> List (Html Msg)
view char model =
    let
        thumbnails =
            model.glyphs
            |> Dict.values
            |> List.map (viewThumbnail char)

        columnHeadings =
            List.map (\title -> Html.th [] [ Html.text title ])
                [ "path"
                , "point"
                , "x"
                , "y"
                , "radians/pi"
                , "curviness"
                ]

        tableRows =
            case Dict.get char model.glyphs of
                Just glyph ->
                    viewGlyphEdit glyph

                _ ->
                    []
    in
    [ Html.div
        [ Attribute.style "font-size" "32px"
        , Attribute.style "color" "#000000"
        ]
        thumbnails
    , Html.form
        [ Event.onSubmit NewCharSubmit
        ]
        [ Html.input
            [ Event.onInput NewCharChange
            , Attribute.value <|
                case model.newChar of
                    Just charValue ->
                        String.fromChar charValue

                    Nothing ->
                        ""
            ]
            []
        , Html.input
            [ Attribute.type_ "submit"
            , Attribute.value "Add character"
            ]
            []
        ]
    , Html.hr [] []
    , Glyph.view
        { initAppearance
        | height = 512
        , grid = True
        }
        (Dict.get char model.glyphs)
    , Html.table
        []
        (Html.tr [] columnHeadings :: tableRows)
    , Html.button
        [ Event.onClick (PathAdd char)
        ]
        [ Html.text "Add path"
        ]
    , Html.hr [] []
    , Html.button
        [ Event.onClick EditFinish
        ]
        [ Html.text "START TESTING" ]
    ]

viewThumbnail : Char -> Glyph -> Html Msg
viewThumbnail currentChar glyph =
    let
        slug =
            glyph
            |> Glyph.char
            |> String.fromChar
    in
    Html.a
        [ Attribute.style "margin-right" "32px"
        , Attribute.href ("/new/" ++ slug)
        , Attribute.style "font-size" "16px"
        , Attribute.style "border" <|
            case (==) currentChar (Glyph.char glyph) of
                True ->
                    "4px solid #000000"

                False ->
                    "0px solid #000000"
        ]
        [ Glyph.view
            { initAppearance
            | height = 24
            }
            (Just glyph)
        , Html.text (String.fromChar (Glyph.char glyph))
        ]

viewGlyphEdit : Glyph -> List (Html Msg)
viewGlyphEdit glyph =
    let
        pointRow : Int -> (Int -> Glyph.Point -> Html Msg)
        pointRow pathId =
            viewPointEdit (Glyph.char glyph) pathId
            |> Html.Lazy.lazy2
    in
    glyph
    |> Glyph.paths
    |> List.indexedMap
        (\pathId path ->
            let
                existingPoints =
                    path.points
                    |> List.indexedMap (pointRow pathId)

                newPoint =
                    Html.tr
                        []
                        [ Html.td
                            []
                            [ Html.text (String.fromInt pathId)
                            ]
                        , Html.td
                            []
                            [ Html.button
                                [ Event.onClick <| PointAdd
                                    (Glyph.char glyph)
                                    pathId
                                ]
                                [ Html.text "Add point"
                                ]
                            ]
                        ]
            in
            existingPoints ++ [ newPoint ]
        )
    |> List.concat

viewPointEdit : Char -> Int -> Int -> Glyph.Point -> Html Msg
viewPointEdit char pathId pointId point =
    let
        numInput :
            (Float -> Glyph.Point)
            -> (Glyph.Point -> Float)
            -> Html Msg
        numInput numToPoint getNum =
            Html.input
                [ Event.onInput <|
                    String.toFloat
                    >> Maybe.withDefault 0
                    >> numToPoint
                    >> PointChange char pathId pointId
                , Attribute.value (point |> getNum |> String.fromFloat)
                ]
                []
    in
    Html.tr
        []
        (List.map (\element -> Html.td [] [element])
            [ Html.text (String.fromInt pathId)
            , Html.text (String.fromInt pointId)
            , numInput
                (\n -> {point | x = n})
                .x
            , numInput
                (\n -> {point | y = n})
                .y
            , numInput
                {-
                0.00 up
                0.25
                0.50 right
                0.75
                1.00 down
                1.25
                1.50 left
                1.75
                -}
                (\n -> {point | radians = n * Basics.pi})
                (.radians >>
                    (\n ->
                        (n / Basics.pi)
                        -- Prevent precision errors with floats
                        -- otherwise you type 11 and see 10.999
                        |> (*) 360
                        |> Basics.round
                        |> Basics.toFloat
                        |> (\n_ -> n_ / 360)
                    )
                )
            , numInput
                (\n -> {point | curviness = n})
                .curviness
            ]
        )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NewCharChange newChar ->
            (
                { model
                | newChar =
                    String.uncons newChar
                    |> Maybe.map Tuple.first
                }
            ,
                Cmd.none
            )

        NewCharSubmit ->
            case model.newChar of
                Just char ->
                    { model | newChar = Nothing }
                    |> updateGlyph
                        (Maybe.withDefault (Glyph.init char) >> Just)
                        char

                Nothing ->
                    (model, Cmd.none)

        PathAdd char ->
            model
            |> updateGlyph
                (Maybe.map Glyph.addPath)
                char

        PointAdd char pathId ->
            model
            |> updateGlyph
                (Maybe.map (Glyph.addPoint pathId))
                char

        PointChange char pathId pointId point ->
            model
            |> updateGlyph
                (Maybe.map (Glyph.setPoint pathId pointId point))
                char

        EditFinish ->
            ( model
            , Lamdera.sendToBackend (ProgressAdd model.glyphs)
            )

        GlyphsRestore glyphs ->
            ( { model | glyphs = glyphs }
            , Cmd.none
            )

updateGlyph : (Maybe Glyph -> Maybe Glyph) -> Char -> Model -> (Model, Cmd Msg)
updateGlyph f char model =
    case f (Dict.get char model.glyphs) of
        Just newGlyph ->
            ( { model | glyphs = model.glyphs |> Dict.insert char newGlyph }
            , Lamdera.sendToBackend (NewGlyphSave newGlyph)
            )

        Nothing ->
            (model, Cmd.none)
