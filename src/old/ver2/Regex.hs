module Regex(parseRegex,t) where

import Data.Char
import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State

{-
regex - '/' --> body
body - nterm not * / \ --> First char
body - \ nterm --> First char
first char -- nterm not / \ --> otherchars
first char -- \ nterm  --> otherchars
other chars -- '/' --> regex2
other chars -- nterm not / \ --> otherchars
others chars -- \ nterm  --> otherchars
regex2 -- ipart --> flags
regex2 -- end ---> stop
flags -- ipart --> flags
flags -- end --> stop
-}


data LState = Start | Body | FirstChar | OtherChars | Flags | State2 | Stop deriving Show

type P = ErrorT String Identity 


isNTerm c = isPrint c

isFirstChar c = isNTerm c && not (elem c [ '*', '/', '\\'])
isOtherChar c = isNTerm c && not (elem c [ '/', '\\'])
isBSeq c c' =  c == '\\' && isNTerm c'



parseRegex str = runIdentity $ runErrorT $ parseRegex' Start str
		      

doit str = (runIdentity $ runErrorT $ parseRegex' Start str) 

parseRegex' :: LState -> String -> P (String,String)
parseRegex' Start ('/':s) = parseRegex' Body s  >>= fn '/'
parseRegex' Start _ = throwError "expecting '/'"

parseRegex' Body (c:s) | isFirstChar c =  parseRegex' FirstChar s  >>= fn c
parseRegex' Body (c:c':s) | isBSeq c c' = parseRegex' FirstChar s >>= (\(s,r) -> return $ ((c:c':s),r))

parseRegex' FirstChar (c:s) | isOtherChar c  =  parseRegex' OtherChars s  >>= fn c
parseRegex' FirstChar (c:c':s) | isBSeq c c' = parseRegex' OtherChars s   >>= (\(s,r) -> return $ ((c:c':s),r))
parseRegex' FirstChar ('/':s) = parseRegex' State2 s  >>= fn '/'

parseRegex' OtherChars  (c:s) | isOtherChar c  =  parseRegex' OtherChars s  >>= fn c
parseRegex' OtherChars  (c:c':s) | isBSeq c c'  = parseRegex' OtherChars s   >>= (\(s,r) -> return $ ((c:c':s),r))
parseRegex' OtherChars ('/':s) = parseRegex' State2 s  >>= fn '/'

parseRegex' State2 (c:s) | isAlpha c = parseRegex' Flags s >>= fn c
parseRegex' State2 r = return ([],r)

parseRegex' Flags (c:s) | isAlpha c = parseRegex' Flags s  >>= fn c
parseRegex' Flags r = return ([],r)

parseRegex' st s = throwError $ "Not implemented <" ++ (show st) ++ "> <" ++ s ++ ">"

fn :: Char -> (String,String) -> P (String ,String)
fn c (s,r) = return $ ((c:s),r)

t = do
       s <- readFile "../test/parsingonly/regex.txt"
       putStrLn $ show $ parseRegex s