# Structure

Repository structure and mapping from thesis circuits to Circom templates.

## Repository

The Ballot Validity repository has the following structure:

```bash
.
├── assets
│   ├── InstallationGuide.md
│   └── Structure.md # You are here
├── libs
│   └── node_modules
│       └── circomlib
├── QuickStart.md
├── README.md
├── setup.sh
├── src
│   ├── benchmarks
│   │   ├── benchmark.py
│   │   ├── benchmarkTestSuite.py
│   │   ├── circomConfig.json
│   │   ├── plotting
│   │   │   ├── plotBenchmarks.py
│   │   │   ├── plotConfig.json
│   │   │   ├── plots
│   │   │   ├── plotSuiteCombined.json
│   │   │   ├── plotSuiteEncryption.json
│   │   │   └── plotSuiteVoting.json
│   │   ├── testSuites
│   │   │   ├── testConfig.json
│   │   │   ├── testSuiteCombined.json
│   │   │   ├── testSuiteEncryption.json
│   │   │   ├── testSuite.py
│   │   │   └── testSuiteVoting.json
│   │   └── thesis_results
│   ├── circom
│   │   ├── curves
│   │   │   ├── affinePoint.circom
│   │   │   ├── conversionsPointRepresentations.circom
│   │   │   ├── curveMembership.circom
│   │   │   ├── montgomeryGroupLaw.circom
│   │   │   ├── montgomeryLadder.circom
│   │   │   ├── montgomeryScalarMul.circom
│   │   │   ├── projectivePoint.circom
│   │   │   ├── twistedEdwardsCurve.circom
│   │   │   └── yRecovery.circom
│   │   ├── expElGamal
│   │   │   ├── assertEEG.circom
│   │   │   └── expElGamal.circom
│   │   ├── utilities
│   │   │   ├── arithmetic.circom
│   │   │   ├── asserts.circom
│   │   │   ├── bitify.circom
│   │   │   ├── branching.circom
│   │   │   └── comparators.circom
│   │   └── voting
│   │       ├── bordaTournamentStyle.circom
│   │       ├── condorcet.circom
│   │       ├── lineVote.circom
│   │       ├── majorityJudgement.circom
│   │       ├── multiVote.circom
│   │       ├── multiVoteWithRules.circom
│   │       ├── pointlistBorda.circom
│   │       └── singleVote.circom
│   ├── sage
│   └── scripts
│       ├── cleanWithGitignore.sh
│       ├── genCircom.sh
│       ├── JSON.py
│       ├── ptau
│       │   └── powersOfTau28_hez_final_22.ptau
│       ├── sageImport.py
│       └── snarkjs
│           ├── createProof.sh
│           ├── prepareProof.sh
│           └── verifyProof.sh
└── Thesis_Roehr.pdf
```

## Circuits

In the thesis `Thesis_Roehr.pdf`, we used the symbol $\mathfrak{C}$ to denote circuits. Now, we provide a mapping between the circuits in the thesis and the corresponding templates in our implementation.
Note that the full ballot validity circuit $\mathfrak{C}_C^{Ballot\text{-}Validity}$ is custom-built from the subcircuits $\mathfrak{C}_{C}^{Enc}$ and $\mathfrak{C}_C^{Vot}$ for each test in the execution of the corresponding `python3 benchmark.py ...` command.

### `src/circom/curves`

|Thesis                             |Circom Template                |Circom File                           |
|-----------------------------------|-------------------------------|--------------------------------------|
|$\mathfrak{C}_{I}$<br>$\mathfrak{C}_{I^{-1}}$|`affineToProjective()`<br>`projectiveToAffine()`|`conversionsPointRepresentations.circom`|
|$\mathfrak{C}_{Tangent\text{-}Rule}$ using Montgomery parameters $A,B$<br>$\mathfrak{C}_{Chord\text{-}Rule}$ using Montgomery parameters $A,B$<br>$\mathfrak{C}_{M_{A,B}(\mathbb{F})\_\odot}$<br>$\mathfrak{C}_{M_{A,B}(\mathbb{F}P^2)\_\odot}$|`tangentRuleAffine(A, B)`<br>`chordRuleAffine(A, B)`<br>`addAffine(A, B)`<br>`addProjective(A, B)`|`montgomeryGroupLaw.circom`|
|$\mathfrak{C}_{xAdd}$<br>$\mathfrak{C}_{xDbl}$ using Montgomery parameter $A$<br>$\mathfrak{C}_{Montgomery\text{-}Ladder}$ for exponent with $n$ bits and Montgomery Parameter $A$|`xAddProjective()`<br>`xDblProjective(A)`<br>`ladderProjective(n, A)`|`montgomeryLadder.circom`|
|$\mathfrak{C}_{M_{A,B}(\mathbb{F}P^2)\_Exp}$ for exponent with $n$ bits|`scalarMulProjective(n, A, B)`|`montgomeryScalarMul.circom`|
|$\mathfrak{C}_{Pro\_If\text{-}Else}$<br>$\mathfrak{C}_{Norm\text{-}Projective}$|`ifThenElseProjective()`<br>`normalizeProjective()`|`projectivePoint.circom`|
|$\mathfrak{C}_{TE_{a,d}(\mathbb{F})\_If\text{-}Else}$<br>$\mathfrak{C}_{TE_{a,d}(\mathbb{F})\_\odot}$<br>$\mathfrak{C}_{TE_{a,d}(\mathbb{F})\_Switch\text{-}Case}$<br>$\mathfrak{C}_{TE_{a,d}(\mathbb{F})\_PPFExp}$ for exponent with $n$ bits<br>$\mathfrak{C}_{TE_{a,d}(\mathbb{F})\_PPFExp_{base}}$ for exponent with $n$ digits|`ifThenElseEdwards()`<br>`twistedEdwardsGroupLaw(a,d)`<br>`switchCaseTwistedEdwards()`<br>`twistedEdwardsScalarMul(n, a, d)`<br>`twistedEdwardsScalarMulArbitraryBase(base, n, a, d)`|`twistedEdwardsCurve.circom`|
|$\mathfrak{C}_{OkSak\text{-}Y\text{-}Recovery}$ with Montgomery parameters $A, B$<br>$\mathfrak{C}_{Ladder\text{-}Y\text{-}Recovery}$ with Montgomery parameters $A, B$|`okeyaSakuraiYRecoveryProjective(A, B)`<br>`yRecoveryProjective(A, B)`|`yRecovery.circom`|

### `src/circom/expElGamal`

|Thesis                             |Circom Template                |Circom File                           |
|-----------------------------------|-------------------------------|--------------------------------------|
|$\mathfrak{C}_{EEG(M_{126932,1}(\mathbb{F}P^2)).Enc}$ using $bitsPlain$ for the message and $bitsRand$ for the randomness<br>$\mathfrak{C}_{PPEEG(TE_{126934,126930}(\mathbb{F})).Enc}$ using $bitsPlain$ for the message and $bitsRand$ for the randomness|`exElGamalMontgomeryProjective(bitsRand, bitsPlain, 126932, 1)`<br>`expElGamalTwistedEdwards(bitsRand, bitsPlain, 126934, 126930)`|`expElGamal.circom`|
|$\mathfrak{C}_{C}^{Enc}$ for one ballot entry, using $bitsPlain$ for the message and $bitsRand$ for the randomness|`assertEncMontgomeryProjective(bitsRand, bitsPlain, 126932, 1)`<br>`assertEncTwistedEdwards(bitsRand, bitsPlain, 126934, 126930)`|`assertEEG.circom`|

### `src/circom/utilities`

|Thesis                             |Circom Template                |Circom File                           |
|-----------------------------------|-------------------------------|--------------------------------------|
|$\mathfrak{C}_{Division}$<br>$\mathfrak{C}_{Safe\text{-}Division}$|`division()`<br>`divisionSafe()`|`arithmetic.circom`|
|$\mathfrak{C}_{Assert\text{-}Bit}$<br>$\mathfrak{C}_{Assert\text{-}Less}$ using $n$ bits for the inputs<br>$\mathfrak{C}_{Assert\text{-}Leq}$ using $n$ bits for the inputs<br>$\mathfrak{C}_{Assert\text{-}Greater}$ using $n$ bits for the inputs<br>$\mathfrak{C}_{Assert\text{-}Geq}$ using $n$ bits for the inputs|`assertBit()`<br>`assertLt(n)`<br>`assertLtEq(n)`<br>`assertGt(n)`<br>`assertGtEq(n)`|`asserts.circom`|
|$\mathfrak{C}_{If\text{-}Else}(n)$<br>$\mathfrak{C}_{Switch\text{-}Case}(n)$<br>$\mathfrak{C}_{Switch\text{-}Case}(n,m)$|`ifThenElseMulti(n)`<br>`switchCase(n)`<br>`switchCaseMulti(n,m)`|`branching.circom`|
|$\mathfrak{C}_{Is\text{-}Bit}$|`isBit()`|`comparators.circom`|

### `src/circom/voting`

|Thesis                             |Circom Template                |Circom File                           |
|-----------------------------------|-------------------------------|--------------------------------------|
|$\mathfrak{C}_{C_{\text{BTS}(nVotes, a, b)}}^{Vot}$ using $bitsVotes$ for ballot entries<br>$\mathfrak{C}_{Count\text{-}Greater}(n)$<br>$\mathfrak{C}_{Count\text{-}Equal}(n)$         |`assertBordaTournamentStyleVoting(bitsVotes, nVotes, a, b)`<br>`countGreater(n)`<br>`countEqual(n)`|`bordaTournamentStle.circom`|
|$\mathfrak{C}_{C_{\text{Condorcet}(n)}}^{Vot}$ with ranking, using $bitsVotes$ for ballot entries<br>$\mathfrak{C}_{C_{\text{Condorcet}(n)}}^{Vot}$ without ranking, using $bitsVotes$ for ballot entries<br> $\mathfrak{C}_{Compute\text{-Condorcet}(n)}$ using $maxValueBits$ to represent ranking entries        |`assertCondorcetVoting(bitsVotes, n)`<br>`assertCondorcetVotingWithoutRanking(n)`<br>`computeCondorcetBallot(n, maxValueBits)`|`condorcet.circom`|
|$\mathfrak{C}_{C_{\text{Line}(nVotes)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertLineVoteVoting(bitsVotes, nVotes)`|`lineVote.circom`|
|$\mathfrak{C}_{C_{\text{Majority-Judgment}(nCand, nGrades)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertMajorityJudgmentVoting(bitsVotes, nCand, nGrades)`|`majorityJudgement.circom`|
|$\mathfrak{C}_{C_{\text{Multi-Vote}(nVotes, maxChoices, maxVotesCand)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertMultiVoteVoting(bitsVotes, nVotes, maxVotesCand, maxChoices)`|`multiVote.circom`|
|$\mathfrak{C}_{C_{\text{MWR}(nVotes, maxChoices, maxVotesCand)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertMultiVoteWithRulesVoting(bitsVotes, nVotes, maxVotesCand, maxChoices)`|`multiVoteWithRules.circom`|
|$\mathfrak{C}_{C_{\text{Pointlist-Borda}(nCand, nPoints, orderedPoints)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertPointlistBordaVoting(bitsVotes, nCand, nPoints, orderedPoints)`|`pointlistBorda.circom`|
|$\mathfrak{C}_{C_{\text{Sinlge}(nVotes)}}^{Vot}$ using $bitsVotes$ for ballot entries         |`assertSingleVoteVoting(bitsVotes,nVotes)`|`singleVote.circom`|
