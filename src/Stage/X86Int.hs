module Stage.X86Int (module Stage.X86Int) where

import Data.HashMap.Strict (HashMap, toList)
import Data.Kind (Type)
import Data.List (List)

import Prettyprinter

import GHC.Records (HasField (getField))

import Core (Label, Name)
import Stage.X86 (InstrF, Reg)

type Arg :: Type
data Arg = Imm Int | Reg Reg | Deref Int Reg
  deriving stock (Show)

instance Pretty Arg where
  pretty = \case
    Imm n -> pretty "$" <> pretty n
    Reg r -> pretty "%" <> pretty r
    Deref n r -> pretty n <> parens (pretty "%" <> pretty r)

type Instr :: Type
type Instr = InstrF Arg

type Frame :: Type
data Frame = MkFrame {env :: HashMap Name Arg, offset :: Int}

instance HasField "size" Frame Int where
  getField MkFrame{offset} = let n = negate offset in (n `mod` 16) + n

type Block :: Type
newtype Block = MkBlock (List Instr)
  deriving stock (Show)

instance Pretty Block where
  pretty (MkBlock xs) = vsep (map (align . pretty) xs)

type Program :: Type
data Program = MkProgram {globl :: Label, blocks :: HashMap Label Block}
  deriving stock (Show)

instance Pretty Program where
  pretty MkProgram{globl, blocks} =
    pretty ".globl" <+> pretty globl <> hardline <> vsep (map ln (toList blocks)) <> line
   where
    ln (lbl, block) = pretty lbl <> colon <> line <> indent 4 (pretty block)
