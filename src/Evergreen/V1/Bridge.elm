module Evergreen.V1.Bridge exposing (..)

import Dict
import Evergreen.V1.Main.Glyph


type ToBackend
    = NewGlyphSave Evergreen.V1.Main.Glyph.Glyph
    | ProgressAdd (Dict.Dict Char Evergreen.V1.Main.Glyph.Glyph)
    | GlyphRequest Int (Maybe Float)