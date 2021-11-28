module Frontend exposing
    ( app
    )

import Bridge exposing (ToBackend(..))
import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attribute
import Html.Events as Event
import Html.Lazy
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
import Main.Route as Route exposing (Route)
import Task
import Time
import Types exposing (FrontendMsg(..), ToFrontend(..))
import Url exposing (Url)

type alias Model =
    Types.FrontendModel

type alias Msg =
    Types.FrontendMsg

app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlRequest
        , onUrlChange = UrlChange
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }

init : Url -> Browser.Navigation.Key -> (Model, Cmd Msg)
init url navigationKey =
    (
        { url = url
        , navigationKey = navigationKey
        , startTime = Time.millisToPosix 0
        , currentGlyph = Nothing
        , newGlyphs = Dict.empty
        , newChar = ""
        }
    ,
        Cmd.none
    )

view : Model -> Browser.Document Msg
view model =
    { title =
        "Fonts"
    , body =
        case Route.fromUrl model.url of
            Route.NotFound ->
                [ Html.text "Page not found"
                ]

            Route.Test id ->
                [ Html.div
                    [ Attribute.style "display" "flex"
                    , Attribute.style "flex-direction" "row"
                    , Attribute.style "align-content" "center"
                    ]
                    [ Glyph.view
                        { height = 32
                        }
                        model.currentGlyph
                    ]
                , Html.input
                    [ Attribute.style "width" "100%"
                    , Attribute.style "height" "64px"
                    , Event.onFocus TextFocus
                    , Event.onInput (TextChange id)
                    , Attribute.value ""
                    ]
                    []
                ]

            Route.NewGlyphs char ->
                let
                    thumbnails =
                        model.newGlyphs
                        |> Dict.values
                        |> List.map viewThumbnail

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
                        case Dict.get char model.newGlyphs of
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
                        , Attribute.value model.newChar
                        ]
                        []
                    , Html.input
                        [ Attribute.type_ "submit"
                        , Attribute.value "Add characters"
                        ]
                        []
                    ]
                , Html.hr [] []
                , Html.table
                    []
                    (Html.tr [] columnHeadings :: tableRows)
                ]
    }

viewThumbnail : Glyph -> Html Msg
viewThumbnail glyph =
    let
        slug =
            glyph
            |> Glyph.char
            |> String.fromChar
    in
    Html.a
        [ Attribute.style "margin-right" "32px"
        , Attribute.href ("/new/" ++ slug)
        ]
        [ Glyph.view
            { height = 24
            }
            (Just glyph)
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
            path.points
            |> List.indexedMap (pointRow pathId)
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
                (\n -> {point | radians = n * Basics.pi})
                (.radians >> (\n -> n / Basics.pi))
            , numInput
                (\n -> {point | curviness = n})
                .curviness
            ]
        )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UrlRequest request ->
            ( model
            , case request of
                Browser.Internal url ->
                    Browser.Navigation.pushUrl
                        model.navigationKey
                        (Url.toString url)

                Browser.External url ->
                    Browser.Navigation.load
                        url
            )

        UrlChange url ->
            ( { model | url = url }
            , case Route.fromUrl url of
                Route.Test id ->
                    Lamdera.sendToBackend (GlyphRequest id Nothing)

                _ ->
                    Cmd.none
            )

        NewCharChange newChar ->
            ( { model | newChar = newChar }
            , Cmd.none
            )

        NewCharSubmit ->
            { model | newChar = "" }
            |> updateNewGlyphs
                (model.newChar
                    |> String.toList
                    |> List.map (\char -> (char, Glyph.init char))
                    |> Dict.fromList
                )

        PointChange char pathId pointId point ->
            model
            |> updateNewGlyphs
                (case Dict.get char model.newGlyphs of
                    Just glyph ->
                        Dict.empty
                        |> Dict.insert char
                            ( glyph
                                |> Glyph.setPoint pathId pointId point
                            )

                    Nothing ->
                        Dict.empty
                )

        TextFocus ->
            ( model
            , Task.perform StartTimeChange Time.now
            )

        StartTimeChange time ->
            ( { model | startTime = time }
            , Cmd.none
            )

        TextChange id string ->
            case (==)
                (model.currentGlyph |> Maybe.map Glyph.char)
                (String.uncons string |> Maybe.map Tuple.first)
            of
                False ->
                    ( model
                    , Cmd.none
                    )

                True ->
                    ( model
                    , Task.perform (EndTime id) Time.now
                    )

        EndTime id endTime ->
            ( { model | currentGlyph = Nothing }
            , Lamdera.sendToBackend
                ( GlyphRequest
                    id
                    ( Just <| toFloat <| (-)
                        (Time.posixToMillis endTime)
                        (Time.posixToMillis model.startTime)
                    )
                )
            )

updateNewGlyphs : Dict Char Glyph -> Model -> (Model, Cmd Msg)
updateNewGlyphs newItems model =
    Tuple.pair
        { model
        | newGlyphs =
            model.newGlyphs
            |> Dict.union newItems
        }
        (Lamdera.sendToBackend (NewGlyphsSave newItems))

updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
updateFromBackend msg model =
    case msg of
        GlyphChange tuple ->
            ( { model | currentGlyph = Just tuple }
            , Task.perform StartTimeChange Time.now
            )

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
