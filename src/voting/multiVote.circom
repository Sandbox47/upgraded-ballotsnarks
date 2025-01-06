pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";

/**
* Assert that in a ballot with n votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
*/
template assertMultiVote(n, maxVotesCand, maxChoices) {
    input signal ballot[n];

    var maxVotesCandBits = numBits(maxVotesCand);
    var maxChoicesBits = numBits(maxChoices);

    component assertLtEq[n];
    component assertSumLtEq = assertLtEq(maxChoicesBits);

    var sum = 0;

    for(var i = 0; i < n; i++) {
        assertLtEq[i] = assertLtEq(maxVotesCandBits);
        assertLtEq[i].in <== ballot[i];
        assertLtEq[i].test <== maxVotesCand;
        sum += ballot[i];
    }

    assertSumLtEq.in <== sum;
    assertSumLtEq.test <== maxChoices;
}

// component main = assertMultiVote(100, 10, 50);