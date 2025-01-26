pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "multiVote.circom";
include "../utilities/branching.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../expElGamal/assertEEG.circom";


/**
* Assert that in a ballot with nVotes votes, each vote is at most maxVotesCand and that the sum of all votes is at most maxChoices.
* As an example for an additional rule, we also enforce that the product of the sedond and third entry in the ballot equals the first one.
*/
template assertMultiVoteWithRulesVoting(nVotes, maxVotesCand, maxChoices) {
    input signal ballot[nVotes];

    component assertMultiVote = assertMultiVoteVoting(nVotes, maxVotesCand, maxChoices);
    assertMultiVote.ballot <== ballot;

    component assertLength = assertGt(2);
    assertLength.in <== nVotes;
    assertLength.test <== 2;

    ballot[1] * ballot[2] === ballot[0];
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
template assertMultiVoteWithRules(bitsVotes, bitsRand, A, B, nVotes, maxVotesCand, maxChoices) {
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

    component assertVoting = assertMultiVoteWithRulesVoting(nVotes, maxVotesCand, maxChoices);
    assertVoting.ballot <== ballot;
}

component main = assertMultiVoteWithRules(32, 255, 126932, 1, 10, 2, 5);