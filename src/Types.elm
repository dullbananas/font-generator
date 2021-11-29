module Types exposing (..)

import Bridge
import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Lamdera
import Main.Glyph as Glyph exposing (Glyph)
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
    , newGlyphs : Dict Char Glyph
    , newChar : String
    }

type FrontendMsg
    = UrlRequest Browser.UrlRequest
    | UrlChange Url
    | NewCharChange String
    | NewCharSubmit
    | PathAdd Char
    --| PointAdd Char Int
    | PointChange Char Int Int Glyph.Point
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
