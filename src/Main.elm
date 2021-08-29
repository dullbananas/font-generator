module Main exposing
    ( main
    )

import Browser
import Browser.Dom
import Browser.Events
import Html
import Html.Attributes exposing (style)
import Html.Events
import Main.Progress as Progress exposing (Progress)
import Process
import Task
import Time

type alias Model =
    { progress : Progress
    , focusTime : Time.Posix
    }

type Msg
    = DoNothing
    | TextInput String
    | AttemptChar Char Time.Posix
    | TextFieldFocus
    | SetFocusTime Time.Posix
    | TextFieldBlur
    | SetStartTime Time.Posix
    | Frame Time.Posix

main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : () -> (Model, Cmd Msg)
init _ =
    Tuple.pair
        { progress = Progress.default
        , focusTime = Time.millisToPosix 0
        }
        Cmd.none

view : Model -> Browser.Document Msg
view model =
    { title = "Font genetic algorithm"
    , body =
        [ Progress.viewCurrentGlyph model.progress
        , Html.input
            [ Html.Events.onInput TextInput
            , Html.Events.onFocus TextFieldFocus
            , Html.Attributes.id "in"
            , style "height" "32px"
            , Html.Attributes.value ""
            ]
            []
        --, Html.text (Debug.toString model.progress.startTime)
        , Progress.viewAllGlyphs model.progress
        ]
    }

thenUpdate : Msg -> (Model, Cmd Msg) -> (Model, Cmd Msg)
thenUpdate msg (model, cmd) =
    let
        (model2, cmd2) =
            update msg model
    in
        (model2, Cmd.batch [cmd, cmd2])

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        DoNothing ->
            Tuple.pair
                model
                Cmd.none
        
        TextInput string ->
            case String.uncons string of
                Just (char, _) ->
                    Tuple.pair
                        model
                        (Time.now
                        |> Task.perform (AttemptChar char)
                        )

                Nothing ->
                    Tuple.pair
                        model
                        Cmd.none

        AttemptChar char time ->
            Tuple.pair
                { model
                | progress =
                    model.progress
                    |> Progress.attemptChar char time
                }
                Cmd.none
                |> thenUpdate (SetFocusTime time)

        TextFieldFocus ->
            Tuple.pair
                model
                (Cmd.batch
                    [ Time.now
                        |> Task.perform SetStartTime
                    --, Process.sleep 4000
                    --    |> Task.andThen (\_ -> Browser.Dom.blur "in")
                    --    |> Task.attempt (\_ -> Blurred)
                    ]
                )
        
        SetFocusTime time ->
            Tuple.pair
                { model
                | focusTime = time
                }
                Cmd.none

        TextFieldBlur ->
            Tuple.pair
                model
                Cmd.none

        SetStartTime time ->
            Tuple.pair
                { model
                | progress =
                    model.progress
                    |> Progress.setStartTime time
                }
                Cmd.none
                |> thenUpdate (SetFocusTime time)
        
        Frame time ->
            Tuple.pair
                model
                (case (Time.posixToMillis time) > (Time.posixToMillis model.focusTime) + 4000 of
                    True ->
                        Browser.Dom.blur "in"
                        |> Task.attempt (\_ -> DoNothing)

                    False ->
                        Cmd.none
                )

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrame Frame
        ]
