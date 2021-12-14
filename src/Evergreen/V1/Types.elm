module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Evergreen.V1.Bridge
import Evergreen.V1.Main.Glyph
import Evergreen.V1.Main.Page.NewGlyphs
import Evergreen.V1.Main.Page.Test
import Evergreen.V1.Main.Progress
import Lamdera
import Random
import Url


type alias FrontendModel =
    { url : Url.Url
    , navigationKey : Browser.Navigation.Key
    , test : Evergreen.V1.Main.Page.Test.Model
    , newGlyphs : Evergreen.V1.Main.Page.NewGlyphs.Model
    }


type alias BackendModel =
    { progress : (Dict.Dict Int Evergreen.V1.Main.Progress.Progress)
    , seed : Random.Seed
    , newGlyphs : (Dict.Dict Lamdera.SessionId (Dict.Dict Char Evergreen.V1.Main.Glyph.Glyph))
    }


type FrontendMsg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url.Url
    | TestRedirect Int
    | NewGlyphsMsg Evergreen.V1.Main.Page.NewGlyphs.Msg
    | TestMsg Evergreen.V1.Main.Page.Test.Msg


type alias ToBackend =Evergreen.V1.Bridge.ToBackend


type BackendMsg
    = N


type ToFrontend
    = ToFrontend FrontendMsg