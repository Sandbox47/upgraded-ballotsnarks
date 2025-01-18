pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";
include "../expElGamal/assertEEG.circom";


/**
* Assert that in a ballot with nVotes votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
*/
template assertMultiVoteVoting(nVotes, maxVotesCand, maxChoices) {
    input signal ballot[nVotes];

    var maxVotesCandBits = numBits(maxVotesCand);
    var maxChoicesBits = numBits(maxChoices);

    component assertLtEq[nVotes];
    component assertSumLtEq = assertLtEq(maxChoicesBits);

    var sum = 0;

    for(var i = 0; i < nVotes; i++) {
        assertLtEq[i] = assertLtEq(maxVotesCandBits);
        assertLtEq[i].in <== ballot[i];
        assertLtEq[i].test <== maxVotesCand;
        sum += ballot[i];
    }

    assertSumLtEq.in <== sum;
    assertSumLtEq.test <== maxChoices;
}

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertMultiVote(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nVotes];
    input signal r[nVotes]; // Randomness

    component assertEnc = assertEncVector(nVotes, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== encBallot[0];
    assertEnc.gv_pkr <== encBallot[1];

    component assertVoting = assertMultiVoteVoting(nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}

component main = assertMultiVote(32, 255, 126932, 1, 10, 2, 5);