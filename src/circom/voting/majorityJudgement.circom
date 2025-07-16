pragma circom 2.2.1;

include "singleVote.circom";
include "../utilities/arithmetic.circom";
include "../utilities/asserts.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../../../libs/node_modules/circomlib/circuits/gates.circom";

/**
* Checks that a given ballot conforms to the Majority Judgement Election type.
* nCand is the number of Candidates and nGrades is the number of grades.
* For each candidate (rows in the ballot matrix) exactly one of the grades should be set (entry is 1) and the others should be 0.
*/
template assertMajorityJudgementVoting(bitsVotes, nCand, nGrades) {
    input signal ballot[nCand][nGrades];

    component assertBit[nCand][nGrades];

    for(var i = 0; i < nCand; i++) {
        var sum = 0;
        for(var j = 0; j < nGrades; j++) {
            assertBit[i][j] = assertBit();
            assertBit[i][j].in <== ballot[i][j];
            sum += ballot[i][j];
        }
        sum === 1;
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
