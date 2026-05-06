module Regex.Parser where

import Control.Applicative
import Regex.Core
import Data.Char (isAlphaNum)

newtype Parser a = Parser 
    { runParser :: String -> Maybe (a, String)
    }

instance Functor Parser where
    fmap f parser = 
        Parser $ \input -> 
            case runParser parser input of
                Nothing -> 
                    Nothing
                
                Just (value, rest) -> 
                    Just (f value, rest)

instance Applicative Parser where
    pure value = 
        Parser $ \input -> Just (value, input)

    functionParser <*> valueParser = 
        Parser $ \input -> 
            case runParser functionParser input of 
                Nothing -> 
                    Nothing 

                Just (f, rest) -> 
                    case runParser valueParser rest of
                        Nothing -> 
                            Nothing 
                        
                        Just (value, rest') -> 
                            Just (f value, rest')

instance Alternative Parser where
    empty = 
        Parser $ \_ -> Nothing 
    
    left <|> right = 
        Parser $ \input -> 
            case runParser left input of 
                Nothing -> 
                    runParser right input
                
                success -> 
                    success

instance Monad Parser where
  parser >>= f =
    Parser $ \input ->
      case runParser parser input of
        Nothing ->
          Nothing
        Just (value, rest) ->
          runParser (f value) rest


item :: Parser Char 
item = Parser $ \input ->
    case input of 
        [] -> Nothing
        (x:xs) -> Just (x, xs)

satisfy :: (Char -> Bool) ->  Parser Char
satisfy predicate = Parser $ \input -> 
    case runParser item input of
        Nothing ->
            Nothing

        Just (x, xs) -> 
            if predicate x
                then Just (x, xs)
                else Nothing

char :: Char -> Parser Char
char c = 
    satisfy (== c)

symbol :: Parser Reg
symbol = Sym <$> satisfy isLiteral

isLiteral :: Char -> Bool
isLiteral c = 
    isAlphaNum c

parseOnly :: Parser a -> String -> Maybe a
parseOnly parser input = 
    case runParser parser input of 
        Just (value, "") -> 
            Just value
        
        _ -> 
            Nothing

concatRegex :: Parser Reg
concatRegex =
  foldSeq <$> some repeatRegex

foldSeq :: [Reg] -> Reg
foldSeq [] = 
    Eps
foldSeq [regex] = 
    regex
foldSeq (regex : regexes) = 
    Seq regex (foldSeq regexes)

optionalChar :: Char -> Parser Bool
optionalChar c =
  (True <$ char c) <|> pure False

repeatRegex :: Parser Reg
repeatRegex = do
  regex <- symbol
  hasStar <- optionalChar '*'
  pure $
    if hasStar
      then Rep regex
      else regex
