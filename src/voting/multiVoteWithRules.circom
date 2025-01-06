pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "multiVote.circom";
include "../utilities/branching.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";

/**
* Assert that in a ballot with n votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
* As an example for an additional rule, we also enforce that the product of the sedond and third entry in the ballot equals the first one.
*/
template assertMultiVoteWithRules(n, maxVotesCand, maxChoices) {
    input signal ballot[n];

    component assertMultiVote = assertMultiVote(n, maxVotesCand, maxChoices);
    assertMultiVote.ballot <== ballot;

    component assertLength = assertGt(2);
    assertLength.in <== n;
    assertLength.test <== 2;

    ballot[1] * ballot[2] === ballot[0];
}

component main = assertMultiVoteWithRules(100, 10, 50);