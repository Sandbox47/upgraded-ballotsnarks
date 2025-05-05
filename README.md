# ZK-SNARKS for Ballot Validity
Circom implementation of Circuits for generating proofs of ballot validity for ballots encrypted with Exponential ElGamal (EEG) using either Montgomery Curves or Twisted Edwards Curves as the basis for encryption. For Twisted Edwards Curves, we use Precomputed Powers EEG (PPEEG) to compute the ballot validity proofs which utilizes some precomputed powers of group elements in the encryption to reduce the computational effort for the encrpytion.

We support the following election types:
- Single-Vote
- Multi-Vote
- Line-Vote
- Multi-Vote with Rules (MWR)
- Pointlist-Borda
- Borda Tournament Style (BTS)
- Condorcet
- Majority Judgment

This repository is the accompanying implementation to the bachelor thesis "Comparative Analysis of zk-SNARK Instantiations for Ensuring Ballot Validity" by Felix Röhr. This work is also included in this repository as `Thesis_Roehr.pdf`.