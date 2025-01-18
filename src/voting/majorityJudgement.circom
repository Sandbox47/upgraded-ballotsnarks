pragma circom 2.2.1;

include "singleVote.circom";
include "../utilities/arithmetic.circom";
include "../utilities/asserts.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../../libs/node_modules/circomlib/circuits/gates.circom";

/**
* Checks that a given ballot conforms to the Majority Judgement Election type.
* nCand is the number of Candidates and nGrades is the number of grades.
* For each candidate (rows in the ballot matrix) exactly one of the grades should be set (entry is 1) and the others should be 0.
*/
template assertMajorityJudgementVoting(nCand, nGrades) {
    input signal ballot[nCand][nGrades];

    component assertRow[nCand];

    for(var i = 0; i < nCand; i++) {
        assertRow[i] = assertSingleVoteVoting(nGrades);
        assertRow[i].ballot <== ballot[i];
    }
}

/**
* Checks that a given ballot conforms to the Majority Judgement Election type.
* nCand is the number of Candidates and nGrades is the number of grades.
* For each candidate the number in the ballot should be in {0, nGrades - 1}
*
* Problem: Has some problems in the later evaluation of the ballots (for example for computing the median of aggregated ballots)
*/
template assertMajorityJudgementWithRangeChecksVoting(nCand, nGrades) {
    input signal ballot[nCand];

    component assertGrade[nCand];
    var nGradesBits = numBits(nGrades);
    for(var i = 0; i < nCand; i++) {
        assertGrade[i] = assertLt(nGradesBits);
        assertGrade[i].in <== ballot[i];
        assertGrade[i].test <== nGrades;
    }
}

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertMajorityJudgement(bitsVotes, bitsRand, A, B, nCand, nGrades) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input ProjectivePoint() encBallot[2][nCand][nGrades]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nCand][nGrades];
    input signal r[nCand][nGrades]; // Randomness

    component assertEnc = assertEncMatrix(nCand, nGrades, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== encBallot[0];
    assertEnc.gv_pkr <== encBallot[1];

    component assertVoting = assertMajorityJudgementVoting(nCand, nGrades);
    assertVoting.ballot <== ballot;
}

// component main = assertMajorityJudgementVoting(100, 100);
// component main = assertMajorityJudgementWithRangeChecksVoting(100, 100);
component main = assertMajorityJudgement(32, 255, 126932, 1, 10, 6);