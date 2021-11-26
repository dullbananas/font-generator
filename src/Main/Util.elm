module Main.Util exposing
    ( awaitGenerator
    )

import Random exposing (Generator)

-- https://package.elm-lang.org/packages/b0oh/elm-do/latest/
awaitGenerator : Generator a -> (a -> Generator b) -> Generator b
awaitGenerator generator continue =
    -- generator and continue are swapped
    generator
    |> Random.andThen continue
