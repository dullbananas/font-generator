module Main.Page.Test exposing
    ( Model, init, view
    , Msg(..), update
    )

import Bridge exposing (ToBackend(..))
import Html exposing (Html)
import Html.Attributes as Attribute
import Html.Events as Event
import Lamdera
import Main.Glyph as Glyph exposing (Glyph, initAppearance)
import Task exposing (Task)
import Time

type alias Model =
    { startTime : Time.Posix
    , glyph : Maybe Glyph
    }

type Msg
    = TextFocus
    | StartTimeChange Time.Posix
    | TextChange Int String
    | EndTime Int Time.Posix
    | GlyphChange Glyph

init : Model
init =
    { startTime = Time.millisToPosix 0
    , glyph = Nothing
    }

view : Int -> Model -> List (Html Msg)
view id model =
    [ Html.div
        [ Attribute.style "display" "flex"
        , Attribute.style "flex-direction" "row"
        , Attribute.style "align-content" "center"
        ]
        [ Glyph.view
            { initAppearance
            | height = 32
            }
            model.glyph
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
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
                (model.glyph |> Maybe.map Glyph.char)
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
            ( { model | glyph = Nothing }
            , Lamdera.sendToBackend
                ( GlyphRequest
                    id
                    ( Just <| toFloat <| (-)
                        (Time.posixToMillis endTime)
                        (Time.posixToMillis model.startTime)
                    )
                )
            )

        GlyphChange glyph ->
            ( { model | glyph = Just glyph }
            , Task.perform StartTimeChange Time.now
            )
