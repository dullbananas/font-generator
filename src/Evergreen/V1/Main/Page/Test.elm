module Evergreen.V1.Main.Page.Test exposing (..)

import Evergreen.V1.Main.Glyph
import Time


type alias Model = 
    { startTime : Time.Posix
    , glyph : (Maybe Evergreen.V1.Main.Glyph.Glyph)
    }


type Msg
    = TextFocus
    | StartTimeChange Time.Posix
    | TextChange Int String
    | EndTime Int Time.Posix
    | GlyphChange Evergreen.V1.Main.Glyph.Glyph