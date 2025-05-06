pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../curves/projectivePoint.circom";
include "../expElGamal/expElGamal.circom";
include "../expElGamal/assertEEG.circom";

/**
* Assert that in a ballot with nVotes votes, each vote is 0 or one and that exactly one vote is one.
*/
template assertSingleVoteVoting(bitsVotes, nVotes) {
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
