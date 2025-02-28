pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";
include "multiVote.circom";
include "../utilities/branching.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../expElGamal/assertEEG.circom";


/**
* Assert that in a ballot with nVotes votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
* As an example for an additional rule, we also enforce that the product of the second and third entry in the ballot equals the first one.
* Requires a list of length nVotes >= 3.
*/
template assertMultiVoteWithRulesVoting(bitsVotes, nVotes, maxVotesCand, maxChoices) {
    input signal ballot[nVotes];

    component assertMultiVote = assertMultiVoteVoting(bitsVotes, nVotes, maxVotesCand, maxChoices);
    assertMultiVote.ballot <== ballot;

    // var nVotesBits = numBits(nVotes);
    // component assertLength = assertGt(nVotesBits);
    // assertLength.in <== nVotes;
    // assertLength.test <== 2;

    ballot[1] * ballot[2] === ballot[0];
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertMultiVoteWithRules(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
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

    component assertVoting = assertMultiVoteWithRulesVoting(nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertMultiVoteWithRules(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
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

    component assertVoting = assertMultiVoteWithRulesVoting(bitsVotes, nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}

// ========================================================================================================================
// BENCHMARKS

template assertMultiVoteWithRulesEncryptionBenchmark(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
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

template assertMultiVoteWithRulesVotingBenchmark(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertVoting = assertMultiVoteWithRulesVoting(bitsVotes, nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}