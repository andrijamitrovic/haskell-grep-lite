module Regex.Core where

data Reg
  = Eps
  | Sym Char
  | Alt Reg Reg
  | Seq Reg Reg
  | Rep Reg
  deriving (Eq, Show)
  
accept :: Reg -> String -> Bool
accept Eps input =
  null input
accept (Sym c) input =
  input == [c]
accept (Alt left right) input =
  accept left input || accept right input
accept (Seq left right) input =
  or
    [ accept left prefix && accept right suffix
      | (prefix, suffix) <- split input
    ]accept (Rep regex) input =
  or
    [ all (accept regex) pieces
      | pieces <- parts input
    ]

split :: [a] -> [([a], [a])]
split [] =
  [([], [])]
split (x : xs) =
  ([], x : xs) : [(x : prefix, suffix) | (prefix, suffix) <- split xs]

parts :: [a] -> [[[a]]]
parts [] =
  [[]]
parts [x] =
  [[[x]]]
parts (x : xs) =
  concat
    [ [(x : piece) : rest, [x] : piece : rest]
      | piece : rest <- parts xs
    ]
