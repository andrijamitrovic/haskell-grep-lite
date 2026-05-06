module Regex.Parser where

import Control.Applicative
import Regex.Core

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