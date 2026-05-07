module Main where

import Regex.Core
import Regex.Parser
import System.Environment (getArgs)
import Tests (runTests)

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--test"] ->
      runTests
    [patternText, filePath] ->
      runGrep patternText filePath
    _ ->
      putStrLn "usage: haskell-grep-lite PATTERN FILE"

runGrep :: String -> FilePath -> IO ()
runGrep patternText filePath =
  case parseRegex patternText of
    Nothing ->
      putStrLn "invalid regex"
    Just regex -> do
      contents <- readFile filePath
      mapM_
        putStrLn
        [ line
          | line <- lines contents,
            matchesAnywhere regex line
        ]
