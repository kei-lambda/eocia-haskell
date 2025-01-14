{-# LANGUAGE OverloadedStrings #-}

module Pipeline (module Pipeline) where

import Data.HashMap.Strict (findWithDefault, insert)

import Core (MonadGensym (gensym), Name (MkName, getName))
import Stage.LVar qualified as LVar

passUniquify :: (MonadGensym m) => LVar.Expr -> m LVar.Expr
passUniquify = loop mempty
 where
  loop env = \case
    e@(LVar.Lit _) -> pure e
    LVar.Var n -> pure $ LVar.Var (findWithDefault n n env)
    LVar.Let name expr body -> do
      name' <- MkName <$> gensym (getName name <> ".")
      expr' <- loop env expr
      body' <- loop (insert name name' env) body
      pure $ LVar.Let name' expr' body'
    e@(LVar.NulApp _) -> pure e
    LVar.UnApp op a -> LVar.UnApp op <$> loop env a
    LVar.BinApp op a b -> LVar.BinApp op <$> loop env a <*> loop env b
