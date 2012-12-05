import Text.Regex.PCRE
import Text.Regex.Base.RegexLike
import System
import Data.Array((!))
--import Text.Regex

type Code                 = [Char]
type Regexp               = [Char]
type Matches              = [(Int,Int)]

mComments = "/\\*[^*]*\\*+([^/][^*]*\\*+)*/"

getMatches                :: Regexp -> Code -> Matches
getMatches pat cs         = getAllMatches (match regex cs) :: [(MatchOffset,MatchLength)]
                              where
                                regex = makeRegexOpts (defaultCompOpt + compCaseless) defaultExecOpt pat

getSubMatches             :: Regexp -> Code -> Matches
getSubMatches pat cs      = getAllSubmatches (match regex cs) :: [(MatchOffset,MatchLength)]
                              where
                                regex = makeRegexOpts (defaultCompOpt + compCaseless) defaultExecOpt pat

-- Some testing functions

findPat                   :: [Char] -> Code -> IO()
findPat pattern code      = do
                              putStrLn ("\nMatches:\n--------\n\nOffset, Length: Code extract\n")
                              putStrLn (concat [show offset ++ ", "
                                                ++ show length ++ ": "
                                                ++ take length (drop offset code)
                                                ++ "\n" | (offset,length) <- matches])
                              where
                                matches = getMatches pattern code
                                
                                
findPatFile               :: String -> String -> IO()
findPatFile file pattern  = do
                              input <- readFile file
                              findPat pattern input



{- | Replaces every occurance of the given regexp with the replacement string.

In the replacement string, @\"\\1\"@ refers to the first substring;
@\"\\2\"@ to the second, etc; and @\"\\0\"@ to the entire match.
@\"\\\\\\\\\"@ will insert a literal backslash.

This does not advance if the regex matches an empty string.  This
misfeature is here to match the behavior of the the original
Text.Regex API.
-}

subRegex :: Regex                          -- ^ Search pattern
         -> String                         -- ^ Input string
         -> String                         -- ^ Replacement text
         -> String                         -- ^ Output string
subRegex _ "" _ = ""
subRegex regexp inp repl =
  let compile _i str [] = \ _m ->  (str++)
      compile i str (("\\",(off,len)):rest) =
        let i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
        in if null str' then \ _m -> (pre ++) . ('\\':)
             else \  m -> (pre ++) . ('\\' :) . compile i' str' rest m
      compile i str ((xstr,(off,len)):rest) =
        let i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
            x = read xstr
        in if null str' then \ m -> (pre++) . ((fst (m!x))++)
             else \ m -> (pre++) . ((fst (m!x))++) . compile i' str' rest m
      compiled :: MatchText String -> String -> String
      compiled = compile 0 repl findrefs where
        -- bre matches a backslash then capture either a backslash or some digits
        bre = mkRegex "\\\\(\\\\|[0-9]+)"
        findrefs = map (\m -> (fst (m!1),snd (m!0))) (matchAllText bre repl)
      go _i str [] = str
      go i str (m:ms) =
        let (_,(off,len)) = m!0
            i' = off+len
            pre = take (off-i) str
            str' = drop (i'-i) str
        in if null str' then pre ++ (compiled m "")
             else pre ++ (compiled m (go i' str' ms))
  in go 0 inp (matchAllText regexp inp)
      
-- | Makes a regular expression with the default options (multi-line,
-- case-sensitive).  The syntax of regular expressions is
-- otherwise that of @egrep@ (i.e. POSIX \"extended\" regular
-- expressions).
mkRegex :: String -> Regex
mkRegex s = makeRegexOpts opt defaultExecOpt s
  where opt = (defaultCompOpt + compCaseless)