module Types exposing (..)

import Bridge
import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
import Main.Page.NewGlyphs as NewGlyphs
import Main.Progress as Progress exposing (Progress)
import Random
import Time
import Url exposing (Url)

type alias BackendModel =
    { progress : Dict Int Progress
    , seed : Random.Seed
    , newGlyphs : Dict Lamdera.SessionId (Dict Char Glyph)
    }

type alias FrontendModel =
    { url : Url
    , navigationKey : Browser.Navigation.Key
    , startTime : Time.Posix
    , currentGlyph : Maybe Glyph
    , newGlyphs : NewGlyphs.Model
    }

type FrontendMsg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url
    | NewGlyphsMsg NewGlyphs.Msg
    | TextFocus
    | StartTimeChange Time.Posix
    | TextChange Int String
    | EndTime Int Time.Posix

type alias ToBackend =
    Bridge.ToBackend

type BackendMsg
    = N

type ToFrontend
    = GlyphChange Glyph
