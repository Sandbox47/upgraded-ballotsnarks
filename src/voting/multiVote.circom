pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";
include "../expElGamal/assertEEG.circom";


/**
* Assert that in a ballot with nVotes votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
*/
template assertMultiVoteVoting(bitsVotes, nVotes, maxVotesCand, maxChoices) {
    input signal ballot[nVotes];

    // var maxVotesCandBits = numBits(maxVotesCand);
    // var maxChoicesBits = numBits(maxChoices);
    var totalBits = bitsVotes + numBits(nVotes); // Number of bits required for the sum of all entries at most
    // log("Total Bits: ", totalBits);

    component assertLtEq[nVotes];
    component assertSumLtEq = assertLtEq(totalBits);

    var sum = 0;

    for(var i = 0; i < nVotes; i++) {
        assertLtEq[i] = assertLtEq(bitsVotes);
        assertLtEq[i].in <== ballot[i];
        assertLtEq[i].test <== maxVotesCand;
        sum += ballot[i];
    }
    // log("Sum: ", sum);
    // log("Max choices:", maxChoices);

    assertSumLtEq.in <== sum;
    assertSumLtEq.test <== maxChoices;
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertMultiVote(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component enc = expElGamalVector(bitsVotes, bitsRand, A, B, nVotes);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertMultiVoteVoting(nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertMultiVote(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVector(nVotes, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;

    component assertVoting = assertMultiVoteVoting(bitsVotes, nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}

// ========================================================================================================================
// BENCHMARKS

template assertMultiVoteEncryptionBenchmark(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVector(nVotes, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;
}

template assertMultiVoteVotingBenchmark(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertVoting = assertMultiVoteVoting(bitsVotes, nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}
