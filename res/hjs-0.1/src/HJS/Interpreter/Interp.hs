{-# OPTIONS -fglasgow-exts #-}
{-# OPTIONS -fallow-overlapping-instances  #-}
module HJS.Interpreter.Interp where

import Control.Monad.Identity
import Control.Monad.Error
import Control.Monad.State


import HJS.Parser.JavaScript

import Data.Map (Map,fromList,lookup,empty,insert)

class SubType sub sup where
    inj :: sub -> sup
    prj :: sup -> Maybe sub

instance SubType a (Either a b) where
   inj = Left
   prj (Left x) = Just x
   prj _ = Nothing

instance SubType a b => SubType a (Either c b) where
   inj = Right . inj
   prj (Right a) = prj a
   prj _ = Nothing

data Ref = Ref String deriving Show

-- Think I should be including Ref (ie what is returned by LeftExpr) into the Value type.
type Value = Either Int (Either String (Either Ref ()))
type Term = AddExpr

data MyError = NoMsg | Msg String deriving Show

instance Error MyError where
	 noMsg = NoMsg
	 strMsg = Msg 		 
    


type InterpM  = StateT (Map String Value) (ErrorT String Identity)

instance Show a => Show (InterpM a) where
     show s = show $ runIdentity $ runErrorT $ (runStateT s empty)

class InterpC t where
    interp  :: t -> InterpM Value
   

instance (InterpC t1, InterpC t2) => InterpC (Either t1 t2) where
   interp (Left x) = interp x
   interp (Right x) = interp x

instance InterpC Literal where
   interp (LitInt i) = unitInj i

instance InterpC PrimExpr where
   interp (Literal l) = interp l
   interp (Ident s)   = return $ inj (Ref s)



instance InterpC MemberExpr where
   interp (MemPrimExpr p) = interp p


instance InterpC NewExpr  where
   interp (MemberExpr  p) = interp p

-- LeftExpr will return a reference
instance InterpC LeftExpr where
   interp (NewExpr n) = interp n



-- PostFix returns a real value, so this is where references get dereferenced
instance InterpC PostFix where
   interp (LeftExpr l) = do 
			    r <- interp l
                            getValue r

   interp (PostInc l) = do 
			    r <- interp l
                            v <- getValue r -- TODO fixme.
                            v' <- getValue r `bindPrj` \ i -> 
                                   unitInj (i+ 1)
                            putValue r v'
                            return v


instance InterpC UExpr where
   interp (PostFix p) = interp p
  
instance InterpC AddExpr where
   interp (MultExpr x) = interp x
   interp (Plus x y) = liftIt (+) x y
   interp (Minus x y) = liftIt (-) x y

instance InterpC ShiftE where
   interp (AddExpr p) = interp p

instance InterpC RelE where
   interp (ShiftE p) = interp p

instance InterpC EqualE where
   interp (RelE p) = interp p

instance InterpC BitAnd where
   interp (EqualE p) = interp p

instance InterpC BitXOR where
   interp (BitAnd p) = interp p

instance InterpC BitOR where
   interp (BitXOR p) = interp p

instance InterpC LogAnd where
   interp (BitOR p) = interp p

instance InterpC LogOr where
   interp (LogAnd p) = interp p

instance InterpC CondE where
   interp (LogOr p) = interp p

instance InterpC AssignE where
    interp (CondE p) = interp p
    interp (Assign left AssignNormal right) = do 
		                                  v <- interp right
                                                  r <- interp left
                                                  putValue r v
  
instance InterpC Expr where
    interp (AssignE p) = interp p

instance InterpC IfStmt where
    interp (IfElse e s1 s2) = do
                                 b <- interp e
                                 case prj b of
                                       Just (0::Int) -> interp s2
                                       _ -> interp s1

instance InterpC ItStmt where
    interp (DoWhile s e ) = do
                            v <- interp s
                            b <- interp e
                            case prj b of
                                       Just (0::Int) -> return v
                                       _ -> interp (DoWhile s e )

instance InterpC Stmt where
    interp (ExprStmt p) = interp p
    interp (IfStmt p) = interp p
    interp (Block xs) = foldM (\v x -> interp x) (Left 0) xs 
    interp (ItStmt p) = interp p

instance InterpC SourceElement where
    interp (Stmt s) = interp s

instance InterpC JSProgram where
    interp (JSProgram xs) = foldM (\v x -> interp x) (Left 0) xs



liftIt f x y = interp x `bindPrj`\i -> 
               interp y `bindPrj` \j -> 
                   unitInj ((f i j))

liftIt2 g x y = interp x `bindPrj`\i -> 
               interp y `bindPrj` \j -> g i j 

instance InterpC MultExpr where
   interp (UExpr x) = interp x
   interp (Times x y) = liftIt (*) x y
   interp (Div x y) =  liftIt2 (\i j -> 
			   if j == 0 then 
                                 throwError "Divide by Zero"
                           else 
                                 unitInj ((i `div` j )::Int)) x y

   interp (Mod x y) =  liftIt2 (\i j -> 
			   if j == 0 then 
                                 throwError "Divide by Zero"
                           else 
                                 unitInj ((i `mod` j )::Int)) x y

unitInj = return . inj

m `bindPrj` k = 
    m >>= \a -> 
	case (prj a) of
		     Just x -> k x
		     Nothing -> error "Run time error"


-- Get value from environment if Value is a reference, throwError if it isn't
getValue :: Value -> InterpM Value
getValue v = do 
                 env <- get
                 case prj v of 
                     ((Just (Ref s))::Maybe Ref) -> case Data.Map.lookup s env of
                       					Just val -> return val
  						        Nothing -> throwError ("Error: Unbound reference " ++ s)
                     _ -> return v


putValue :: Value -> Value -> InterpM Value
putValue r v = do 
	          env <- get
                  case prj r of 
			((Just (Ref s))::Maybe Ref) -> put (insert s v env) >>= \_ -> return v
                        _ -> throwError "Error: Invalid Reference"
                                                  