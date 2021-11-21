module Bridge exposing
    ( ToBackend(..)
    )

import Dict exposing (Dict)
import Main.Glyph as Glyph exposing (Glyph)

type ToBackend
    = NewGlyphsSave (Dict Char Glyph)
    | GlyphRequest Int (Maybe Float)
