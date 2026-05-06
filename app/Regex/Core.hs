module Regex.Core where

data Reg
  = Eps
  | Sym Char
  | Alt Reg Reg
  | Seq Reg Reg
  | Rep Reg
  deriving (Eq, Show)

data MReg
    = MEps
    | MSym Bool Char
    | MAlt MReg Mreg
    | MSeq MReg MReg
    | MRep MReg
    deriving (Eq, Show)

mark :: Reg -> MReg
mark Eps = 
  MEps
mark (Sym c) = 
  MSym False c
mark (Alt left right) = 
  MAlt (mark left) (mark right)
mark (Seq left right) = 
  MSeq (mark left) (mark right)
mark (Rep regex) = 
  MRep (mark regex)

nullable :: MReg -> Bool
nullable MEps = 
  True
nullable (MSym _ _) = 
  False
nullable (MAlt left right) = 
  nullable left || nullable right
nullable (MSeq left right) = 
  nullable left && nullable right
nullable (MRep _) = 
  True

final :: MReg -> Bool
final MEps = 
  False
final (Msym marked _) = 
  marked
final (MAlt left right) = 
  final left || final right
final (MSeq left right) = 
  final right || (final left && nullable right)
final (MRep regex) =
  final regex

shift :: Bool -> MReg -> Char -> MReg 
shift marked MEps _ = 
  MEps
shift marked (MSym _ c) input = 
  MSym (marked && c == input) c 
shift marked (MAlt left right) input = 
  MAlt
    (shift marked left input)
    (shift marked right input)
shift marked (MSeq left right) input = 
  MSeq
    (shift marked left input)
    (shift ((marked && nullable left) || final left) right input)
shift marked (MRep regex) input = 
  MRep (shift (marked || final regex) regex input)

acceptFast :: Reg -> String -> Bool
acceptFast regex [] = 
  nullable (mark regex)
acceptFast regex (c : cs) = 
  final (foldl (shift False) first cs)
  where
    first = shift True (mark regex) c

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
