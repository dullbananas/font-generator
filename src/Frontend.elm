module Frontend exposing
    ( app
    )

import Bridge exposing (ToBackend(..))
import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Html exposing (Html)
import Html.Attributes as Attribute
import Html.Events as Event
import Lamdera
import Main.Glyph as Glyph exposing (Glyph, initAppearance)
import Main.Page.NewGlyphs as NewGlyphs
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
        , newGlyphs = NewGlyphs.init
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
                        { initAppearance
                        | height = 32
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
                model.newGlyphs
                |> NewGlyphs.view char
                |> List.map (Html.map NewGlyphsMsg)
    }

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

        NewGlyphsMsg subMsg ->
            model.newGlyphs
            |> NewGlyphs.update subMsg
            |> Tuple.mapBoth
                (\a -> { model | newGlyphs = a })
                (Cmd.map NewGlyphsMsg)

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
