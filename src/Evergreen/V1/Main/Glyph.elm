module Evergreen.V1.Main.Glyph exposing (..)

type alias Point = 
    { x : Float
    , y : Float
    , radians : Float
    , curviness : Float
    }


type alias Path = 
    { points : (List Point)
    }


type alias Internals = 
    { paths : (List Path)
    , char : Char
    }


type Glyph
    = Glyph Internals