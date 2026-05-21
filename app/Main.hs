module Main where

import System.Environment (getArgs)
import Tests (runTests)
import Grep.Engine

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
runGrep patternText filePath = do
  contents <- readFile filePath
  case grepText patternText contents of
    Left err ->
      putStrLn err
    Right output ->
      putStr output