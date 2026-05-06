module Main where

import Regex.Core

a :: Reg
a = Sym 'a'

b :: Reg
b = Sym 'b'

ab :: Reg
ab = Seq a b

aOrB :: Reg
aOrB = Alt a b

manyA :: Reg
manyA = Rep a

abStar :: Reg
abStar = Seq a (Rep b)

data TestCase = TestCase
  { testName :: String,
    testRegex :: Reg,
    testInput :: String,
    testExpected :: Bool
  }

tests :: [TestCase]
tests =
  [ TestCase "a matches a" a "a" True,
    TestCase "a does not match b" a "b" False,
    TestCase "ab matches ab" ab "ab" True,
    TestCase "ab does not match a" ab "a" False,
    TestCase "a|b matches b" aOrB "b" True,
    TestCase "a* matches empty string" manyA "" True,
    TestCase "a* matches aaa" manyA "aaa" True,
    TestCase "a* does not match aaab" manyA "aaab" False,
    TestCase "ab* matches a" abStar "a" True,
    TestCase "ab* matches abb" abStar "abb" True
  ]

main :: IO ()
main =
  mapM_ runTest tests

runTest :: TestCase -> IO ()
runTest test =
  putStrLn (status ++ " " ++ testName test)
  where
    slowResult = accept (testRegex test) (testInput test)
    fastResult = acceptFast (testRegex test) (testInput test)

    passed =
      slowResult == testExpected test
        && fastResult == testExpected test
        && slowResult == fastResult

    status =
      if passed then "[OK]" else "[FAIL]"
