module Types exposing (..)

import Bridge
import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
import Main.Page.NewGlyphs as NewGlyphs
import Main.Page.Test as Test
import Main.Progress as Progress exposing (Progress)
import Random
import Url exposing (Url)

type alias BackendModel =
    { progress : Dict Int Progress
    , seed : Random.Seed
    , newGlyphs : Dict Lamdera.SessionId (Dict Char Glyph)
    }

type alias FrontendModel =
    { url : Url
    , navigationKey : Browser.Navigation.Key
    , test : Test.Model
    , newGlyphs : NewGlyphs.Model
    }

type FrontendMsg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url
    | TestRedirect Int
    | NewGlyphsMsg NewGlyphs.Msg
    | TestMsg Test.Msg

type alias ToBackend =
    Bridge.ToBackend

type BackendMsg
    = N

type ToFrontend
    = ToFrontend FrontendMsg
