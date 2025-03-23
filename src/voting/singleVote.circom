pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";
include "../expElGamal/assertEEG.circom";

/**
* Assert that in a ballot with nVotes votes, each vote is 0 or one and that exactly one vote is one.
*/
template assertSingleVoteVoting(nVotes) {
    input signal ballot[nVotes];

    component assertBit[nVotes];
    component assertSumBit = assertBit();

    var sum = 0;

    for(var i = 0; i < nVotes; i++) {
        assertBit[i] = assertBit();
        assertBit[i].in <== ballot[i];
        sum += ballot[i];
    }

    assertSumBit.in <== sum;
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertSingleVote(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private input /witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component enc = expElGamalVector(bitsRand, bitsVotes, A, B, nVotes);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertSingleVoteMontgomeryProjective(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVectorMontgomeryProjective(nVotes, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertSingleVoteTwistedEdwards(bitsVotes, bitsRand, a, d, nVotes) {
    // Public
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input TwistedEdwardsPoint() enc_gr[nVotes];
    input TwistedEdwardsPoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVectorTwistedEdwards(nVotes, bitsVotes, bitsRand, a, d);
    assertEnc.v <== ballot;
    assertEnc.powersOfg <== powersOfg;
    assertEnc.powersOfpk <== powersOfpk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}

// ========================================================================================================================
// BENCHMARKS

// MONTGOMERY

template assertSingleVoteMontgomeryProjectiveEncryptionBenchmark(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVectorMontgomeryProjective(nVotes, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;
}

template assertSingleVoteMontgomeryProjectiveVotingBenchmark(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nVotes];
    input ProjectivePoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}



// TWISTED EDWARDS

template assertSingleVoteTwistedEdwardsEncryptionBenchmark(bitsVotes, bitsRand, a, d, nVotes) {
    // Public
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input TwistedEdwardsPoint() enc_gr[nVotes];
    input TwistedEdwardsPoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVectorTwistedEdwards(nVotes, bitsVotes, bitsRand, a, d);
    assertEnc.v <== ballot;
    assertEnc.powersOfg <== powersOfg;
    assertEnc.powersOfpk <== powersOfpk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;
}

template assertSingleVoteTwistedEdwardsVotingBenchmark(bitsVotes, bitsRand, a, d, nVotes) {
    // Public
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input TwistedEdwardsPoint() enc_gr[nVotes];
    input TwistedEdwardsPoint() enc_gv_pkr[nVotes];

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}