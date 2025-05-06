# Quick Start

Installation instructions and instructions to compute ballot validity proofs.

## Installation

To create proofs of ballot validity, we require Circom, snarkjs and SageMath.
If you have some of this software installed already, you can skip the corresponding installation steps.
Furthermore, if you already have our ballot validity repository on your system, you can skip the first installation step.
Detailed installation instructions are provided in `assets/InstallationGuide.md`.

For convenience, we also provide a `setup.sh` script that can be run after installing our ballot validity repository to install the same dependencies.
Note that in order to run `setup.sh`, your system needs to have at least $4$ cores and that installation may take multiple hours since we install and build SageMath from source.

## Benchmarks

To run benchmarks, navigate to the folder `src/benchmarks`.
We provide the option to run individual benchmarks as well as multiple benchmarks grouped together in test suites.

### Individual Test Cases
The command to run an individual benchmark is:
```bash
python3 benchmark.py <snark> <circuit> <curve> <election> <bits> <election_key_1>=<election_value_1> ... <election_key_n>=<election_value_n>
```

Here, the individual parameters are:
- `<snark>`: Zero Knowledge Proof system (ZPS). At the moment, we support `groth16`, `PLONK` and `FFLONK`. 
Please note that our circuits are not optimized for `PLONK` and `FFLONK` and performance is typically a lot worse for these ZPSs.
- `<circuit>`: Circuit. We can assert that a chosen ballot is in the choice space with `voting` ($\mathfrak{C}_C^{Vot}$ in our thesis), that a ballot is correctly encrypted with `encryption` ($\mathfrak{C}_C^{Enc}$ in our thesis) and we can compute full ballot validity proofs using `combined` ($\mathfrak{C}_C^{Ballot\text{-}Validity}$ in our thesis).
- `<curve>`: Elliptic curve. We can use `twistedEdwards` for the Twsited Edwards curve $TE_{126934, 126930}(\mathbb{F})$ as defined in our thesis. Alternatively, we can use `montgomeryProjective` for the Montgomery curve $M_{126932,1}(\mathbb{F}P^2)$ as defined in our thesis.
- `<election>`: Election type. Here, we support the election types that were covered in our thesis:
    - `singleVote` for choice spaces $C_{\text{Single}(cand)}$
    - `multiVote` for choice spaces $C_{\text{Multi}(cand, max, t)}$
    - `lineVote` for choice spaces $C_{\text{Line}(cand)}$
    - `multiVoteWithRules` for choice spaces $C_{\text{MWR}(cand, max, t)}$
    - `pointlistBorda` for choice spaces $C_{\text{Pointlist-Borda}(cand, l, \mathcal{L})}$
    - `bordaTournamentStyle` for choice spaces $C_{\text{BTS}(cand, ap, bp)}$
    - `condorcet` for choice spaces $C_{\text{Condorcet}(cand)}$
    - `majorityJudgment` for choice spaces $C_{\text{Majority-Judgment}(cand, grades)}$
- `<bits>`: Number of Bits to represent a ballot entry. This is provided as an integer value
- `<election_key_i>=<election_value_i>`: Additional parameters specific to the election type. For the different election types, these are:
    - For `singleVote`: `nVotes=cand` for the choice space $C_{\text{Single}(cand)}$.
    - For `multiVote`: `nVotes=cand maxVotesCand=t maxChoices=max` for the choice space $C_{\text{Multi}(cand, max, t)}$
    - For `lineVote`: `nVotes=cand` for the choice space $C_{\text{Line}(cand)}$
    - For `multiVoteWithRules`: `nVotes=cand maxVotesCand=t maxChoices=max` for the choice space $C_{\text{MWR}(cand, max, t)}$
    - For `pointlistBorda`: `nCand=cand nPoints=l orderedPoints=[p_0,...,p_(l-1)]` for the choice space $C_{\text{Pointlist-Borda}(cand, l, [p_0,\dots, p_{l-1}])}$
    - For `bordaTournamentStyle`: `nVotes=cand a=ap b=bp` for the choice space $C_{\text{BTS}(cand, ap, bp)}$
    - For `condorcet`: `nCand=cand` for the choice space $C_{\text{Condorcet}(cand)}$
    - For `majorityJudgment`: `nCand=cand nGrades=grades` for the choice space $C_{\text{Majority-Judgment}(cand, grades)}$

Consider the following example: We want to compute the complete ballot validity proof for Pointlist-Borda with $20$ candidates and $[5,3,2,1]$ as the pointlist, where the individual ballot entries are represented with $32$ bits, we want to use Exponential ElGamal (EEG) encryption based on Twisted Edwards curves and want to compute the proof with the Groth16 SNARK. Then, we need to run the following command:
```bash
python3 benchmark.py groth16 combined twistedEdwards pointlistBorda 32 nCand=20 nPoints=4 orderedPoints=[5,3,2,1]
```

For every test case with the format specified above, that we run, we record the number of non-linear, linear and total constraint count of the tested circuit, $CRS$ size, $CRS$ generation time, proving time, and verification time. All of these values are saved in the folder `src/benchmarks/<snark>/<curve>/results/<circuit>/<election>.csv` and the number of bits used to represent the ballot entries as well as the election type specific parameters are used to identify the line in the CSV-file. Here, the CSV-file has the following columns:
```csv
<bits>;<election_key_1>;...;<election_key_n>;<non-linear constraints>;<linear constraints>;<total constraints>;<CRS size>[MB];<CRS gen. time>[ms];<proving time>[ms];<verification time>[ms]
```

So, for the Pointlist-Borda example described before, the result would be saved in the folder `src/benchmarks/groth16/twistedEdwards/results/combined/pointlistBorda.csv` and could be for example the following line:
```csv
32;20;4;[5,3,2,1];108500;43845;152345;73.33515930175781;29132;7669;1047
```

The results we obtained using Groth16 and Circom in our thesis as well as the results obtained by Huber et al. using Groth16 and libsnark are saved in the folder `src/benchmarks/thesis_results`.

### Test Suites
To run multiple benchmarks together, we use test suites and a config file to create these. In the folder `src/benchmarks/testSuites`, we provide a `testConfig.json` file. This file is used to generate the test suites and has the following entries:
- `"snark"`: The ZPS used for all test cases in the test suite. This equates to the parameter `<snark>` in the individual benchmarks.
- `"ellipticCurve"`: The elliptic curve used for all test cases in the test suite. This equates to the parameter `<curve>` in the individual benchmarks.
- `"testCircuits"`: A list of circuits used in the test suite. This equates to the parameter `<circuit>` in the individual benchmarks.
- `"bitsVotes"`: A list of bit counts used in the test suite. This equates to the parameter `<bits>` in the individual benchmarks.
- `"nCand"`: A list of candidate counts used in the test suite. This equates to the election type specific parameter `nVotes` or `nCand` in the individual benchmarks depending on the election type.
- `"electionTypes"`: A list of election tpyes used in the test suite. This equates to the parameter `<election>` in the individual benchmarks.

Additionally, the config file contains some presets for other election type specific parameters such as `ap` and `bp` in BTS elections.

We provide a prepared config file with snark `groth16` and elliptic curve `twistedEdwards`.

The test suites containing all test cases specified in `testConfig.json` are then created seperatly for the circuits `voting`, `encryption` and `combined`. By running the command `python3 testSuite.py` in the folder `src/benchmarks/testSuites`, we create the test suites `testSuiteVoting.json`, `testSuiteEncryption.json` and `testSuiteCombined.json` in the same folder. We provide prepared test suites for the test cases specified in our prepared `testConfig.json` file.

In order to run all of the test cases specified in a test suite `testSuite<circuit>.json`, we run the command 
```bash
python3 benchmarkTestSuite.py testSuites/testSuite<circuit>.json
```
in the folder `src/benchmarks`. For instance, to run the test suite `testSuiteVoting.json`, we use the command
```bash
python3 benchmarkTestSuite.py testSuites/testSuiteVoting.json
```

## Plotting

To visualize our results, we provide a `plotBenchmarks.py` file in the folder `src/benchmarks/plotting`. Additionally, we provide a config file `plotConfig.json` which specifies which metrics we want to plot. Furthermore, we provide `plotSuiteVoting.json`, `plotSuiteEncryption.json` and `plotSuiteCombined.json` to plot our results seperatly for the tested circuits `voting`, `encryption` and `combined`. To plot the results from our thesis for a circuit `<circuit>`, we run the command
```bash
python3 plotBenchmarks.py testSuite<circuit>.json
```
in the folder `src/benchmarks/plotting`.
To plot newly generated results, the corresponding occurences of `thesis_results` in the plot suites need to be changed to `groth16`, `PLONK` or `FFLONK` depending on the ZPS used to generate the new results.