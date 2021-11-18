module Main.Route exposing
    ( Route(..)
    , fromUrl
    )

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, (</>))

type Route
    = NotFound
    | Test Int
    | NewGlyphs Char

fromUrl : Url -> Route
fromUrl url =
    url
    |> Parser.parse parser
    |> Maybe.withDefault NotFound

parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Test (Parser.s "test" </> Parser.int)
        , Parser.map NewGlyphs (Parser.s "new" </> parseChar)
        ]

parseChar : Parser (Char -> a) a
parseChar =
    Parser.custom "CHARACTER" (String.toList >> List.head)
