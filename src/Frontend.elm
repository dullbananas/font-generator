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
import Main.Page.NewGlyphs as NewGlyphs
import Main.Page.Test as Test
import Main.Route as Route exposing (Route)
import Task exposing (Task)
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
        , test = Test.init
        , newGlyphs = NewGlyphs.init
        }
    ,
        Cmd.batch
            [ Lamdera.sendToBackend NewGlyphsRequest
            , Task.perform UrlChange (Task.succeed url)
            ]
    )

view : Model -> Browser.Document Msg
view model =
    { title =
        "Fonts"
    , body =
        (++)
            [ Html.input
                [ Event.onInput (Url.fromString >> Maybe.withDefault model.url >> UrlChange)
                , Attribute.value (Url.toString model.url)
                ]
                []
            , Html.br [] []
            ]
        <|
        case Route.fromUrl model.url of
            Route.NotFound ->
                [ Html.text "Page not found"
                ]

            Route.Test id ->
                model.test
                |> Test.view id
                |> List.map (Html.map TestMsg)

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

        TestRedirect id ->
            ( model
            , Browser.Navigation.pushUrl
                model.navigationKey
                ("/test/" ++ String.fromInt id)
            )

        NewGlyphsMsg subMsg ->
            model.newGlyphs
            |> NewGlyphs.update subMsg
            |> Tuple.mapBoth
                (\a -> { model | newGlyphs = a })
                (Cmd.map NewGlyphsMsg)

        TestMsg subMsg ->
            model.test
            |> Test.update subMsg
            |> Tuple.mapBoth
                (\a -> { model | test = a })
                (Cmd.map TestMsg)


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
updateFromBackend (ToFrontend msg) model =
    update msg model

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
