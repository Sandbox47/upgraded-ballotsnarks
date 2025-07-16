# ZK-SNARKS for Ballot Validity
Circom implementation of Circuits for generating proofs of ballot validity for ballots encrypted with Exponential ElGamal (EEG) using either Montgomery Curves or Twisted Edwards Curves as the basis for encryption. For Twisted Edwards Curves, we use Precomputed Powers EEG (PPEEG) in the ballot validity proofs which utilizes some precomputed powers of group elements in the encryption to reduce the computational effort. Additionally, we represent ballot entries and randomnesses used in the encryption in base $5$ to reduce the computational effort further.

We support the following election types:
- Single-Vote
- Multi-Vote
- Line-Vote
- Multi-Vote with Rules (MWR)
- Pointlist-Borda
- Borda Tournament Style (BTS)
- Condorcet
- Majority Judgment

To install the required dependencies and benchmark our implementation, please follow the instructions in `QuickStart.md`.