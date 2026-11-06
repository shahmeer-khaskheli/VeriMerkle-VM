{-# OPTIONS --cubical --safe --guardedness #-}

module VeriMerkle.StateMachine where

open import Agda.Builtin.Nat using (suc)
open import Cubical.Foundations.Prelude using (_≡_; refl)
open import VeriMerkle.Types using
  ( Value
  ; MerkleTree
  ; MachineState
  ; stateTree
  ; stateAddress
  ; stateValue
  ; leaf
  ; node
  )
open import VeriMerkle.HashModel using (HashExpr)
open import VeriMerkle.MerkleTree using (merkleRoot)

data Instruction : Set where
  read       : Instruction
  write      : Instruction
  increment  : Instruction

data Status : Set where
  running : Status
  stopped : Status

record Configuration : Set where
  constructor configuration
  field
    machineState     : MachineState
    instruction      : Instruction
    status           : Status
    stateCommitment  : HashExpr

open Configuration public

rootValue : MerkleTree → Value
rootValue (leaf hash) = hash
rootValue (node hash leftTree rightTree) = hash

replaceRootValue : MerkleTree → Value → MerkleTree
replaceRootValue (leaf _) value = leaf value
replaceRootValue (node _ leftTree rightTree) value =
  node value leftTree rightTree

rootValue-after-replace :
  (tree : MerkleTree) (value : Value) →
  value ≡ rootValue (replaceRootValue tree value)
rootValue-after-replace (leaf hash) value = refl
rootValue-after-replace (node hash leftTree rightTree) value = refl

replaceState : MachineState → MerkleTree → Value → MachineState
replaceState state tree value =
  record
    { stateTree = tree
    ; stateAddress = stateAddress state
    ; stateValue = value
    }

record StateInvariant (config : Configuration) : Set where
  constructor stateInvariant
  field
    valueMatchesRoot :
      stateValue (machineState config) ≡
      rootValue (stateTree (machineState config))
    commitmentMatchesTree :
      stateCommitment config ≡ merkleRoot (stateTree (machineState config))

open StateInvariant public

data Step : Configuration → Configuration → Set where
  step-read :
    (state : MachineState) (commitment : HashExpr) →
    Step
      (configuration state read running commitment)
      (configuration
        (replaceState state (stateTree state) (rootValue (stateTree state)))
        read stopped
        commitment)
  step-write :
    (state : MachineState) (commitment : HashExpr) →
    Step
      (configuration state write running commitment)
      (configuration
        (replaceState state
          (replaceRootValue (stateTree state) (stateValue state))
          (stateValue state))
        write stopped
        (merkleRoot
          (replaceRootValue (stateTree state) (stateValue state))))
  step-increment :
    (state : MachineState) (commitment : HashExpr) →
    Step
      (configuration state increment running commitment)
      (configuration
        (replaceState state
          (replaceRootValue (stateTree state) (suc (stateValue state)))
          (suc (stateValue state)))
        increment stopped
        (merkleRoot
          (replaceRootValue (stateTree state) (suc (stateValue state)))))

Preservation :
  {before after : Configuration} →
  StateInvariant before →
  Step before after →
  StateInvariant after
Preservation (stateInvariant valueProof commitmentProof) (step-read state commitment) =
  stateInvariant refl commitmentProof
Preservation (stateInvariant valueProof commitmentProof) (step-write state commitment) =
  stateInvariant
    (rootValue-after-replace (stateTree state) (stateValue state))
    refl
Preservation (stateInvariant valueProof commitmentProof) (step-increment state commitment) =
  stateInvariant
    (rootValue-after-replace (stateTree state) (suc (stateValue state)))
    refl

data ProgressResult (config : Configuration) : Set where
  makesStep :
    (next : Configuration) →
    Step config next →
    ProgressResult config
  isStopped :
    status config ≡ stopped →
    ProgressResult config

Progress : (config : Configuration) → ProgressResult config
Progress (configuration state read running commitment) =
  makesStep
    (configuration
      (replaceState state (stateTree state) (rootValue (stateTree state)))
      read stopped
      commitment)
    (step-read state commitment)
Progress (configuration state write running commitment) =
  makesStep
    (configuration
      (replaceState state
        (replaceRootValue (stateTree state) (stateValue state))
        (stateValue state))
      write stopped
      (merkleRoot (replaceRootValue (stateTree state) (stateValue state))))
    (step-write state commitment)
Progress (configuration state increment running commitment) =
  makesStep
    (configuration
      (replaceState state
        (replaceRootValue (stateTree state) (suc (stateValue state)))
        (suc (stateValue state)))
      increment stopped
      (merkleRoot
        (replaceRootValue (stateTree state) (suc (stateValue state)))))
    (step-increment state commitment)
Progress (configuration state instruction stopped commitment) =
  isStopped refl
