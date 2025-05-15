pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../utilities/arithmetic.circom";
include "multiVote.circom";
include "../utilities/branching.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";
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

    ballot[1] * ballot[2] === ballot[0];
}
