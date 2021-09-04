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
    , startTime : Time.Posix
    }

type Msg
    = DoNothing
    | InitSeed Time.Posix
    | TextFieldInput String
    | AttemptChar Char Time.Posix
    | TextFieldFocus
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
        { progress = Progress.empty
        , startTime = Time.millisToPosix 0
        }
        (Time.now
            |> Task.perform InitSeed
        )

view : Model -> Browser.Document Msg
view model =
    { title = "Font genetic algorithm"
    , body =
        [ Progress.viewCurrentGlyph model.progress
        , Html.input
            [ Html.Events.onInput TextFieldInput
            , Html.Events.onFocus TextFieldFocus
            , Html.Attributes.id "in"
            , style "height" "32px"
            , Html.Attributes.value ""
            ]
            []
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
        
        InitSeed time ->
            Tuple.pair
                { model
                | progress =
                    Progress.init time
                }
                Cmd.none
        
        TextFieldInput string ->
            Tuple.pair
                model
                (case String.uncons string of
                    Just (char, _) ->
                        Time.now
                        |> Task.perform (AttemptChar char)

                    Nothing ->
                        Cmd.none
                )

        AttemptChar char time ->
            let
                timeDiff : Int
                timeDiff =
                    (-)
                        (Time.posixToMillis time)
                        (Time.posixToMillis model.startTime)
            in
            Tuple.pair
                (case
                    model.progress
                    |> Progress.attemptChar
                        char
                        timeDiff
                of
                    Just newProgress ->
                        { model
                        | progress = newProgress
                        , startTime = time
                        }
                
                    Nothing ->
                        model
                )
                Cmd.none

        TextFieldFocus ->
            Tuple.pair
                model
                (Time.now
                |> Task.perform SetStartTime
                )
        
        SetStartTime time ->
            Tuple.pair
                { model
                | startTime = time
                }
                Cmd.none
        
        Frame time ->
            Tuple.pair
                model
                (case (Time.posixToMillis time) > (Time.posixToMillis model.startTime) + 4000 of
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
