module Tests where

import Regex.Core
import Regex.Parser

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

matchPattern :: String -> String -> Maybe Bool
matchPattern rawPattern input = do
  regex <- parseRegex rawPattern
  pure (acceptFast regex input)

data PatternTestCase = PatternTestCase
  { patternTestName :: String,
    patternText :: String,
    patternInput :: String,
    patternExpected :: Maybe Bool
  }

patternTests :: [PatternTestCase]
patternTests =
  [ PatternTestCase "parsed a matches a" "a" "a" (Just True),
    PatternTestCase "parsed a does not match b" "a" "b" (Just False),
    PatternTestCase "parsed ab matches ab" "ab" "ab" (Just True),
    PatternTestCase "parsed a|b matches b" "a|b" "b" (Just True),
    PatternTestCase "parsed a* matches aaa" "a*" "aaa" (Just True),
    PatternTestCase "parsed a* does not match aaab" "a*" "aaab" (Just False),
    PatternTestCase "parsed (ab)* matches abab" "(ab)*" "abab" (Just True),
    PatternTestCase "parsed a(b|c)* matches abcb" "a(b|c)*" "abcb" (Just True),
    PatternTestCase "invalid regex fails" "a(" "a" Nothing
  ]

runTests :: IO ()
runTests = do
  mapM_ runTest tests
  mapM_ runPatternTest patternTests
  mapM_ runSearchTest searchTests

runTest :: TestCase -> IO ()
runTest test =
  putStrLn (status ++ " " ++ testName test)
  where
    slowResult =
      accept (testRegex test) (testInput test)

    fastResult =
      acceptFast (testRegex test) (testInput test)

    passed =
      slowResult == testExpected test
        && fastResult == testExpected test
        && slowResult == fastResult

    status =
      if passed then "[OK]" else "[FAIL]"

runPatternTest :: PatternTestCase -> IO ()
runPatternTest test =
  putStrLn (status ++ " " ++ patternTestName test)
  where
    result =
      matchPattern (patternText test) (patternInput test)

    passed =
      result == patternExpected test

    status =
      if passed then "[OK]" else "[FAIL]"


searchPattern :: String -> String -> Maybe Bool
searchPattern rawPattern input = do
  regex <- parseRegex rawPattern
  pure (matchesAnywhere regex input)

data SearchTestCase = SearchTestCase
  { searchTestName :: String,
    searchPatternText :: String,
    searchInput :: String,
    searchExpected :: Maybe Bool
  }

searchTests :: [SearchTestCase]
searchTests =
  [ SearchTestCase "search b in abc" "b" "abc" (Just True),
    SearchTestCase "search bc in abc" "bc" "abc" (Just True),
    SearchTestCase "search ac in abc" "ac" "abc" (Just False),
    SearchTestCase "search a|x in zzzabc" "a|x" "zzzabc" (Just True),
    SearchTestCase "search invalid regex fails" "a(" "abc" Nothing
  ]

runSearchTest :: SearchTestCase -> IO ()
runSearchTest test =
  putStrLn (status ++ " " ++ searchTestName test)
  where
    result =
      searchPattern (searchPatternText test) (searchInput test)

    passed =
      result == searchExpected test

    status =
      if passed then "[OK]" else "[FAIL]"
