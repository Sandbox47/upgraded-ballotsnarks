pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";

bus SingleVoteBallot(nVotes) {
    signal votes[nVotes];
}

/**
* Assert that in a ballot with nVotes votes, each vote is 0 or one and that exactly one vote is one.
*/
template assertSingleVoteVoting(nVotes) {
    input signal ballot[nVotes];
    // input SingleVoteBallot(nVotes) ballot;

    component assertBit[nVotes];
    component assertSumBit = assertBit();

    var sum = 0;

    for(var i = 0; i < nVotes; i++) {
        assertBit[i] = assertBit();
        assertBit[i].in <== ballot[i];
        sum += ballot[i];
        // assertBit[i].in <== ballot.votes[i];
        // sum += ballot.votes[i];
    }

    assertSumBit.in <== sum;
}

/**
* nBits is here the number of Bits, 
*/
template singleVoteEnc(nBits, A, B, nVotes) {
    input signal ballot[nVotes];

    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal r[nVotes]; // Randomness

    output ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    component expElGamal = expElGamalVector(nBits, A, B, nVotes);
    expElGamal.g <== g;
    expElGamal.pk <== pk;
    expElGamal.v <== ballot;
    expElGamal.r <== r;

    encBallot[0] <== expElGamal.gr;
    encBallot[1] <== expElGamal.gv_pkr;
}

/**
* Asserts that a given ballot belongs to the given encrypted ballot
*/
template assertSingleVoteEnc(nBits, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component enc = singleVoteEnc(nBits, A, B, nVotes);
    enc.ballot <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;

    encBallot === enc.encBallot;
}

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertSingleVote(nBits, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertSingleVoteEnc(nBits, A, B, nVotes);
    assertEnc.ballot <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.encBallot <== encBallot;

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}

// component main = assertSingleVoteVoting(100);
// component main = assertSingleVoteEnc(32, 126932, 1, 100);
component main = assertSingleVote(32, 126932, 1, 100);