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
template assertSingleVote(bitsVotes, bitsRand, A, B, nVotes) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private input /witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component enc = expElGamalVector(bitsVotes, bitsRand, A, B, nVotes);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertSingleVoteVoting(nVotes);
    assertVoting.ballot <== ballot;
}

// component main = assertSingleVoteVoting(100);
// component main = assertSingleVote(32, 255, 126932, 1, 10);