# Quick Start

Installation instructions and instructions to compute ballot validity proofs.
Note that the installation instructions are for Ubuntu 24.04. 
However, installing should be very similar for other Ubuntu versions and other Linux distributions.
We do not support Windows and macOS.

## Installation

To create proofs of ballot validity, we require Circom, snarkjs and SageMath.
If you have some of this software installed already, you can skip the corresponding installation steps.
Detailed installation instructions for these dependencies that should be performed after installing our ballot validity repository are provided in `assets/InstallationGuide.md`.

NOTE: To run the benchmarks from the paper "Improving the Efficiency of zkSNARKs for Ballot Validity", SageMath is not strictly required. For these cases, we provide prepared input files and the test suite `src/benchmarks/preparedInputs/testPreparedInputs.json`. We can run all test cases in this test suite as described later on. If this is all you need, you can skip the time-consuming installation steps for SageMath.
Nevertheless, for any other test case, we need to provide the precomputed powers of a public EEG key as input to the circuit. Additionally, we need to provide the individual ballot entries and randomnesses used for encryption in the array based representation. We use SageMath to compute these input files.

For convenience, we also provide a `setup.sh` script to install Circom, snarkjs and SageMath.
Note that in order to run `setup.sh`, your system needs to have at least $4$ cores and that the installation may take multiple hours since we install and build SageMath from source.

## Benchmarks

To run benchmarks, navigate to the folder `src/benchmarks`.
We provide the option to run individual benchmarks as well as multiple benchmarks grouped together in test suites.

### Individual Test Cases
The command to run an individual benchmark is:
```bash
python3 benchmark.py [<input>] <snark> <circuit> <curve> <election> <bits> <election_key_1>=<election_value_1> ... <election_key_n>=<election_value_n>
```

Here, the individual parameters are:
- `<input>`: OPTIONAL input file for the circuit with json format. The file provided here must match the circuit specifications by the other parameters. With this option, it is possible to run benchmarks without having Sage istalled. We provide some prepared input files for the cases also covered in the paper in `src/benchmarks/preparedInputs`.
- `<snark>`: Zero Knowledge Proof system (ZPS). At the moment, we support `groth16`, `plonk` and `fflonk`. 
Please note that our circuits are not optimized for `plonk` and `fflonk` and performance is typically a lot worse for these ZPSs.
- `<circuit>`: Circuit. We can assert that a chosen ballot is in the choice space with `voting`, that a ballot is correctly encrypted with `encryption`, and we can compute full ballot validity proofs using `combined`.
- `<curve>`: Elliptic curve. We can use `twistedEdwards` for the Twisted Edwards curve $\{(x,y)| 126934\cdot x^2 + y^2 = 1 + 126930\cdot x^2y^2\}$. Alternatively, we can use `montgomeryProjective` for the Montgomery curve $\{(x,y)| y^2 = x^3 + 126932\cdot x^2 + x\}\cup\{\mathcal{O}\}$.
- `<election>`: Election type. Here, we support the following election types:
    - `singleVote`
    - `multiVote`
    - `lineVote`
    - `multiVoteWithRules`
    - `pointlistBorda`
    - `bordaTournamentStyle`
    - `condorcet`
    - `majorityJudgment`
Note that we always need to specify an election type even if we only test the encryption circuit. Then, the choice of election type does not make a difference as long as the number of ballot entries matches what you want to test. In such cases, we always chose `singleVote` (e.g., see the prepared test cases in `src/preparedInputs/testPreparedInputs` and the corresponding input files `src/preparedInputs/singleVote...`).
- `<bits>`: Number of Bits to represent a ballot entry. This is provided as an integer value
- `<election_key_i>=<election_value_i>`: Additional parameters specific to the election type. For the different election types, these are:
    - For `singleVote`: `nVotes=cand` (For $cand$ candidates).
    - For `multiVote`: `nVotes=cand maxVotesCand=t maxChoices=max` (For $cand$ candidates, maximal number of votes $t$ per candidate, maximal number of votes $max$ in total)
    - For `lineVote`: `nVotes=cand` (For $cand$ candidates)
    - For `multiVoteWithRules`: `nVotes=cand maxVotesCand=t maxChoices=max` (For $cand$ candidates, maximal number of votes $t$ per candidate, maximal number of votes $max$ in total)
    - For `pointlistBorda`: `nCand=cand nPoints=l orderedPoints=[p_0,...,p_(l-1)]` (For $cand$ candidates, and a list of points $[p_0,\dots, p_{l-1}]$ to be given to the different candidates)
    - For `bordaTournamentStyle`: `nVotes=cand a=ap b=bp` (For $cand$ candidates and $ap$ points to be given to a candidate for every candidate ranked worse than them as well as $bp$ points to be given to a candidate for every candidate ranked the same as them)
    - For `condorcet`: `nCand=cand` (For $cand$ candidates)
    - For `majorityJudgment`: `nCand=cand nGrades=grades` (For $cand$ candidates to be graded with $grades$ different grades)

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

The results we obtained using Groth16 and Twisted Edwards curves in our paper are saved in the folder `src/benchmarks/short_paper_results`.

### Test Suites
To run multiple benchmarks together, we use test suites and a config file to create these. In the folder `src/benchmarks/testSuites`, we provide a `testConfig.json` file. This file is used to generate the test suites and has the following entries:
- `"snark"`: The ZPS used for all test cases in the test suite. This equates to the parameter `<snark>` in the individual benchmarks.
- `"ellipticCurve"`: The elliptic curve used for all test cases in the test suite. This equates to the parameter `<curve>` in the individual benchmarks.
- `"testCircuits"`: A list of circuits used in the test suite. This equates to the parameter `<circuit>` in the individual benchmarks.
- `"bitsVotes"`: A list of bit counts used in the test suite. This equates to the parameter `<bits>` in the individual benchmarks.
- `"nCand"`: A list of candidate counts used in the test suite. This equates to the election type specific parameter `nVotes` or `nCand` in the individual benchmarks depending on the election type.
- `"electionTypes"`: A list of election types used in the test suite. This equates to the parameter `<election>` in the individual benchmarks.

Additionally, the config file contains some presets for other election type specific parameters such as `ap` and `bp` in BTS elections.

We provide a prepared config file with snark `groth16` and elliptic curve `twistedEdwards`.

The test suite `src/benchmaks/testSuites/testSuite.json` contains all test cases we performed successfully on an ESPRIMO Q957 (64-bit, i5-7500T CPU@ 2.70GHz, 16 GB RAM).

Furthermore, the test suite `src/benchmarks/preparedInputs/testPreparedInputs.json` contains all test cases for which we provided prepared inputs in the same directory.

In order to run all the test cases specified in a test suite `<suite>.json`, we run the command 
```bash
python3 benchmarkTestSuite.py testSuites/<suite>.json
```
in the folder `src/benchmarks`. For instance, to run the test suite `testPreparedInputs.json`, we use the command
```bash
python3 benchmarkTestSuite.py preparedInputs/testPreparedInputs.json
```