module DefaultGlyphs exposing
    ( data
    )

type alias Pixel =
    { pixel : Int
    }

type alias RowCount a =
    { a
    | rows : Int
    }

type alias PixelCount a =
    { a
    | pixels : Int
    }

blank : Pixel
blank =
    Pixel 0

filled : Pixel
filled =
    Pixel 1

data : List (Char, List Int)
data =
