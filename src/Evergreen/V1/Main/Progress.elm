module Evergreen.V1.Main.Progress exposing (..)

import Dict
import Evergreen.V1.Main.Glyph
import Lamdera


type alias Parent = 
    { glyphs : (Dict.Dict Char Evergreen.V1.Main.Glyph.Glyph)
    , scores : (Dict.Dict Char Float)
    }


type alias Internals = 
    { parentHistory : (List Parent)
    , nextParent : Parent
    , remainingGlyphs : (List Evergreen.V1.Main.Glyph.Glyph)
    , currentGlyphs : (Dict.Dict Lamdera.ClientId Evergreen.V1.Main.Glyph.Glyph)
    , name : String
    }


type Progress
    = Progress Internals