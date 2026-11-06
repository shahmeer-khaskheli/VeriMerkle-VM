{-# OPTIONS --cubical --safe --guardedness #-}

module VeriMerkle.HashModel where

open import VeriMerkle.Types using (Hash)

data HashExpr : Set where
  leafHash : Hash → HashExpr
  nodeHash : Hash → HashExpr → HashExpr → HashExpr
