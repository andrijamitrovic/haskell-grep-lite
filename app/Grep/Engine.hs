module Grep.Engine where
import Regex.Parser
import Regex.Core

grepText :: String -> String -> Either String String
grepText patternText inputText =
  case parseRegex patternText of
    Nothing ->
      Left "invalid regex"
    Just regex ->
      Right $
        unlines
          [ line
          | line <- lines inputText
          , matchesAnywhere regex line
          ]