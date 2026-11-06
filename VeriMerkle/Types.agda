{-# OPTIONS --cubical --safe --guardedness #-}

module VeriMerkle.Types where

open import Agda.Builtin.Nat using (Nat)
open import Agda.Builtin.List using (List; []; _∷_)
open import Cubical.Foundations.Prelude using (_≡_)

ℕ : Set
ℕ = Nat

Hash : Set
Hash = ℕ

Address : Set
Address = ℕ

Value : Set
Value = ℕ

data MerkleTree : Set where
  leaf : Hash → MerkleTree
  node : Hash → MerkleTree → MerkleTree → MerkleTree

data Direction : Set where
  left  : Direction
  right : Direction

Path : Set
Path = List Direction

record MachineState : Set where
  field
    stateTree    : MerkleTree
    stateAddress : Address
    stateValue   : Value

open MachineState public

record Transition : Set where
  field
    fromState : MachineState
    toState   : MachineState
    path      : Path

open Transition public
