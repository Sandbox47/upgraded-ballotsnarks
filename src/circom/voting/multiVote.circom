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

    var totalBits = bitsVotes + numBits(nVotes); // Number of bits required for the sum of all entries at most

    component assertLtEq[nVotes];
    component assertSumLtEq = assertLtEq(totalBits);

    var sum = 0;

    for(var i = 0; i < nVotes; i++) {
        assertLtEq[i] = assertLtEq(bitsVotes);
        assertLtEq[i].in <== ballot[i];
        assertLtEq[i].test <== maxVotesCand;
        sum += ballot[i];
    }

    assertSumLtEq.in <== sum;
    assertSumLtEq.test <== maxChoices;
}
