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

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertMajorityJudgement(bitsVotes, bitsRand, A, B, nCand, nGrades) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nCand][nGrades]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nCand][nGrades];
    input signal r[nCand][nGrades]; // Randomness

    component enc = expElGamalMatrix(bitsVotes, bitsRand, A, B, nCand, nGrades);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertMajorityJudgementVoting(nCand, nGrades);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertMajorityJudgement(bitsVotes, bitsRand, A, B, nCand, nGrades) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nCand][nGrades];
    input ProjectivePoint() enc_gv_pkr[nCand][nGrades];

    // Private/Witness
    input signal ballot[nCand][nGrades];
    input signal r[nCand][nGrades]; // Randomness

    component assertEnc = assertEncMatrix(nCand, nGrades, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;
    
    component assertVoting = assertMajorityJudgementVoting(nCand, nGrades);
    assertVoting.ballot <== ballot;
}

// ========================================================================================================================
// BENCHMARKS

template assertMajorityJudgementEncryptionBenchmark(bitsVotes, bitsRand, A, B, nCand, nGrades) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nCand][nGrades];
    input ProjectivePoint() enc_gv_pkr[nCand][nGrades];

    // Private/Witness
    input signal ballot[nCand][nGrades];
    input signal r[nCand][nGrades]; // Randomness

    component assertEnc = assertEncMatrix(nCand, nGrades, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;
}

template assertMajorityJudgementVotingBenchmark(bitsVotes, bitsRand, A, B, nCand, nGrades) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nCand][nGrades];
    input ProjectivePoint() enc_gv_pkr[nCand][nGrades];

    // Private/Witness
    input signal ballot[nCand][nGrades];
    input signal r[nCand][nGrades]; // Randomness
    
    component assertVoting = assertMajorityJudgementVoting(nCand, nGrades);
    assertVoting.ballot <== ballot;
}

// Test
// component main = assertMajorityJudgement(32, 255, 126932, 1, 25, 25);