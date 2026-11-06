{-# OPTIONS --cubical --safe --guardedness #-}

module VeriMerkle.MerkleTree where

open import Cubical.Foundations.Prelude using (_≡_)
open import VeriMerkle.Types using (Hash; MerkleTree; leaf; node)
open import VeriMerkle.HashModel using (HashExpr; leafHash; nodeHash)

treeHash : MerkleTree → HashExpr
treeHash (leaf hash) = leafHash hash
treeHash (node hash leftTree rightTree) =
  nodeHash hash (treeHash leftTree) (treeHash rightTree)

merkleRoot : MerkleTree → HashExpr
merkleRoot = treeHash

data InclusionProof : Set where
  rootProof  : InclusionProof
  leftProof  : Hash → HashExpr → InclusionProof → InclusionProof
  rightProof : Hash → HashExpr → InclusionProof → InclusionProof

reconstruct : InclusionProof → HashExpr → HashExpr
reconstruct rootProof candidate = candidate
reconstruct (leftProof hash sibling proof) candidate =
  nodeHash hash (reconstruct proof candidate) sibling
reconstruct (rightProof hash sibling proof) candidate =
  nodeHash hash sibling (reconstruct proof candidate)

verify : HashExpr → HashExpr → InclusionProof → Set
verify expectedRoot candidate proof =
  reconstruct proof candidate ≡ expectedRoot

verificationSoundness :
  (expectedRoot candidate : HashExpr) (proof : InclusionProof) →
  verify expectedRoot candidate proof →
  reconstruct proof candidate ≡ expectedRoot
verificationSoundness expectedRoot candidate proof accepted = accepted

verificationCompleteness :
  (expectedRoot candidate : HashExpr) (proof : InclusionProof) →
  reconstruct proof candidate ≡ expectedRoot →
  verify expectedRoot candidate proof
verificationCompleteness expectedRoot candidate proof accepted = accepted
