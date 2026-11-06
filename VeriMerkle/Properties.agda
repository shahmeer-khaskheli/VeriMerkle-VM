{-# OPTIONS --cubical --safe --guardedness #-}

module VeriMerkle.Properties where

open import Cubical.Foundations.Prelude using (_≡_; refl; cong)
open import VeriMerkle.Types using (Hash; MerkleTree; leaf; node; stateTree)
open import VeriMerkle.HashModel using (HashExpr; leafHash; nodeHash)
open import VeriMerkle.MerkleTree using
  ( treeHash
  ; merkleRoot
  ; InclusionProof
  ; reconstruct
  ; verify
  ; verificationSoundness
  ; verificationCompleteness
  )
open import VeriMerkle.StateMachine using
  ( Configuration
  ; machineState
  ; stateCommitment
  ; StateInvariant
  ; Step
  ; Preservation
  )

treeHash-leaf-correct :
  (hash : Hash) →
  treeHash (leaf hash) ≡ leafHash hash
treeHash-leaf-correct hash = refl

treeHash-node-correct :
  (hash : Hash) (leftTree rightTree : MerkleTree) →
  treeHash (node hash leftTree rightTree) ≡
  nodeHash hash (treeHash leftTree) (treeHash rightTree)
treeHash-node-correct hash leftTree rightTree = refl

treeHash-deterministic :
  (firstTree secondTree : MerkleTree) →
  firstTree ≡ secondTree →
  treeHash firstTree ≡ treeHash secondTree
treeHash-deterministic firstTree secondTree equalTrees =
  cong treeHash equalTrees

merkleRoot-correct :
  (tree : MerkleTree) →
  merkleRoot tree ≡ treeHash tree
merkleRoot-correct tree = refl

merkleRoot-deterministic :
  (firstTree secondTree : MerkleTree) →
  firstTree ≡ secondTree →
  merkleRoot firstTree ≡ merkleRoot secondTree
merkleRoot-deterministic firstTree secondTree equalTrees =
  cong merkleRoot equalTrees

inclusion-sound :
  (expectedRoot candidate : HashExpr) (proof : InclusionProof) →
  verify expectedRoot candidate proof →
  reconstruct proof candidate ≡ expectedRoot
inclusion-sound = verificationSoundness

inclusion-complete :
  (expectedRoot candidate : HashExpr) (proof : InclusionProof) →
  reconstruct proof candidate ≡ expectedRoot →
  verify expectedRoot candidate proof
inclusion-complete = verificationCompleteness

stateInvariant-preserved :
  {before after : Configuration} →
  StateInvariant before →
  Step before after →
  StateInvariant after
stateInvariant-preserved = Preservation

record AuthenticatedExecution
  (before after : Configuration) : Set where
  constructor authenticatedExecution
  field
    initialInvariant : StateInvariant before
    authenticationPath : InclusionProof
    candidateAuthenticated :
      verify
        (stateCommitment before)
        (merkleRoot (stateTree (machineState before)))
        authenticationPath
    executionStep : Step before after
    finalInvariant : StateInvariant after

authenticatedStateTransition :
  {before after : Configuration} →
  (initial : StateInvariant before) →
  (proof : InclusionProof) →
  verify
    (stateCommitment before)
    (merkleRoot (stateTree (machineState before)))
    proof →
  (execution : Step before after) →
  AuthenticatedExecution before after
authenticatedStateTransition initial proof authenticated execution =
  authenticatedExecution
    initial
    proof
    authenticated
    execution
    (Preservation initial execution)

authenticatedPrestateTreeCommitment :
  {before after : Configuration} →
  AuthenticatedExecution before after →
  stateCommitment before ≡
  merkleRoot (stateTree (machineState before))
authenticatedPrestateTreeCommitment
  (authenticatedExecution initial proof authenticated execution final) =
  StateInvariant.commitmentMatchesTree initial
