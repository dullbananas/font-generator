module Evergreen.V1.Main.Page.NewGlyphs exposing (..)

import Dict
import Evergreen.V1.Main.Glyph


type alias Model = 
    { glyphs : (Dict.Dict Char Evergreen.V1.Main.Glyph.Glyph)
    , newChar : (Maybe Char)
    }


type Msg
    = NewCharChange String
    | NewCharSubmit
    | PathAdd Char
    | PointAdd Char Int
    | PointChange Char Int Int Evergreen.V1.Main.Glyph.Point
    | EditFinish