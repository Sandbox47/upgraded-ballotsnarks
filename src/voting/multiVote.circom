pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";

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

template multiVoteEnc(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    input signal ballot[nVotes];

    output ProjectivePoint() encBallot[2][nVotes];

    var maxVotesCandBits = numBits(maxVotesCand);
    var maxChoicesBits = numBits(maxChoices);
}

template assertMultiVoteEnc(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
    
}

template assertMultiVote(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {

}

// component main = assertMultiVote(32, 126932, 1, 100, 10, 50);