pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../expElGamal/assertEEG.circom";

/**
* Asserts that in a ballot with nVotes entries, each entry is 0 or 1, and all 1-votes are assigned successively.
* A ballot consisting of only zeros is considered valid.
*/
template assertLineVoteVoting(nVotes) {
    input signal ballot[nVotes];

    component assertBits[nVotes];
    component assertLine = assertBit();

    assertBits[0] = assertBit();
    assertBits[0].in <== ballot[0];

    signal indicator[nVotes];
    indicator[0] <== ballot[0];
    signal tmp[nVotes];


    for(var i = 1; i < nVotes; i++) {
        assertBits[i] = assertBit();
        assertBits[i].in <== ballot[i];

        tmp[i] <== ballot[i] - ballot[i-1];
        indicator[i] <== indicator[i-1] + tmp[i] * ballot[i]; // 1 if there is a change from 0 to 1 from ballot[i-1] to ballot[i], 0 otherwise
    }

    assertLine.in <== indicator[nVotes-1];
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertLineVote(bitsVotes, bitsRand, A, B, nVotes) {
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

    component assertVoting = assertLineVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertLineVote(bitsVotes, bitsRand, A, B, nVotes) {
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

    component assertVoting = assertLineVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}

// ========================================================================================================================
// BENCHMARKS

template assertLineVoteEncryptionBenchmark(bitsVotes, bitsRand, A, B, nVotes) {
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

template assertLineVoteVotingBenchmark(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertVoting = assertLineVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}