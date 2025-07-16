pragma circom 2.2.1;

include "../utilities/arithmetic.circom";
include "../utilities/asserts.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../../../libs/node_modules/circomlib/circuits/gates.circom";
include "../expElGamal/assertEEG.circom";

/**
* Checks that a given ballot (as a (n x n)-Matrix) confirms to the condorcet election type.
* Condorcet Election type defined in "zk-SNARKS for Ballot Validity: A Feasibility Study".
*/
template assertCondorcetVotingWithoutRanking(n) {
    input signal ranking[n]; // For compatibility, but is not used here
    input signal ballot[n][n];

    // Assert that all entries are bits
    component assertBitsEntries[n][n];
    for(var i = 0; i < n; i++) {
        for(var j = 0; j < n; j++) {
            assertBitsEntries[i][j] = assertBit();
            assertBitsEntries[i][j].in <== ballot[i][j];
        }
    }

    // Assert that all sums of entries a_ij + a_ji are bits (when i is not equal to j).
    component assertBitsSumEntries[n][n];
    for(var i = 0; i < n; i++) {
        for(var j = i + 1; j < n; j++) {
            assertBitsSumEntries[i][j] = assertBit();
            assertBitsSumEntries[i][j].in <== ballot[i][j] + ballot[j][i];
        }
    }

    // Assert Transitivity:
    // For any distinct i, j, k in [1,n]:
    // 1. If i is ranked better or equal than j and j is ranked better or equal than k, then i is ranked better or equal than k
    // 2. If i is ranked the same as j and j is ranked the same as k then i is ranked the same as k.
    // We can translate these Cases to Matrix entries:
    // 1. If a_ji = 0 and a_kj = 0, then a_ki = 0
    // 2. If a_ji = a_ij = 0 and a_kj = a_jk = 0, then a_ki = a_ik = 0
    // We are using the check matrix approach presented in "zk-SNARKS for Ballot Validity: A Feasibility Study" to assert this property.

    signal checkMatrix[n][n];
    for(var i = 0; i < n; i++) {
        for(var j = 0; j < n; j++) {
            checkMatrix[i][j] <== 1 - ballot[i][j];
        }
    }
    component assertTransitivity[n][n][n];
    for(var i = 0; i < n; i++) {
        for(var j = 0; j < n; j++) {
            for(var k = 0; k < n; k++) {
                if(i != j && j != k && i != k) {
                    assertTransitivity[i][j][k] = MultiAND(3);

                    assertTransitivity[i][j][k].in[0] <== checkMatrix[i][j];
                    assertTransitivity[i][j][k].in[1] <== checkMatrix[j][k];
                    assertTransitivity[i][j][k].in[2] <== 1 - checkMatrix[i][k];

                    assertTransitivity[i][j][k].out === 0;
                }
            }
        }
    }
}

/**
* Computes the corresponding Condorcet ballot to the ranking. (Since the values on the diagonal have no function, we assume, that those are zero.)
* maxValue is the maximal Value any entry in the ranking should have.
*/
template computeCondorcetBallot(n, maxValueBits) {
    input signal ranking[n];

    output signal out[n][n]; // ballot

    component rankedWorse[n][n];
    component rankedTheSame[n][n];
    component computeEntryIJ[n][n];
    component computeEntryJI[n][n];
    signal tmp[n][n];

    var test = numBits(n);

    for(var i = 0; i < n; i++) {
        for(var j = i; j < n; j++) {
            if(j == i) {
                out[i][j] <== 0;
            } else{
                rankedWorse[i][j] = GreaterThan(maxValueBits); //r_i > r_j implies that i is ranked worse than j.
                rankedTheSame[i][j] = IsEqual(); // r_i = r_j implies that i and ja are ranked the same.
                computeEntryIJ[i][j] = switchCase(3);
                computeEntryJI[i][j] = switchCase(3);

                rankedWorse[i][j].in[0] <== ranking[i];
                rankedWorse[i][j].in[1] <== ranking[j];
                rankedTheSame[i][j].in[0] <== ranking[i];
                rankedTheSame[i][j].in[1] <== ranking[j];

                // tmp[i][j] <== 1 - rankedWorse[i][j].out;

                computeEntryIJ[i][j].cond[0] <== rankedWorse[i][j].out;
                computeEntryIJ[i][j].cond[1] <== rankedTheSame[i][j].out;
                // computeEntryIJ[i][j].s[2] <== tmp[i][j] * (1-rankedTheSame[i][j].out);
                computeEntryIJ[i][j].in[0] <== 0; // a_ij = 0 if i is ranked worse than j
                computeEntryIJ[i][j].in[1] <== 0; // a_ij = 0 if i is ranked the same as j
                computeEntryIJ[i][j].in[2] <== 1; // a_ij = 1 if i is ranked better than j
                out[i][j] <== computeEntryIJ[i][j].out;

                computeEntryJI[i][j].cond[0] <== rankedWorse[i][j].out;
                computeEntryJI[i][j].cond[1] <== rankedTheSame[i][j].out;
                // computeEntryJI[i][j].s[2] <== tmp[i][j] * (1-rankedTheSame[i][j].out);
                computeEntryJI[i][j].in[0] <== 1; // a_ji = 1 if i is ranked worse than j
                computeEntryJI[i][j].in[1] <== 0; // a_ji = 0 if i is ranked the same as j
                computeEntryJI[i][j].in[2] <== 0; // a_ji = 0 if i is ranked better than j
                out[j][i] <== computeEntryJI[i][j].out;
            }
        }
    }
}

/**
* Assert that the given ballot corresponds to the given ranking according to the condorcet election type.
* Parameters n, bitsVotes are defined the same as in computeCondorcetBallot.
*/
template assertCondorcetVoting(bitsVotes, n) {
    input signal ranking[n];
    input signal ballot[n][n];

    component computeBallot = computeCondorcetBallot(n, bitsVotes);
    computeBallot.ranking <== ranking;
    signal computedBallot[n][n] <== computeBallot.out;

    for(var i = 0; i < n; i++) {
        for(var j = 0; j < n; j++) {
            ballot[i][j] === computedBallot[i][j];
        }
    }
    
}
