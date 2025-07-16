pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../expElGamal/assertEEG.circom";

/**
* Asserts that in a ballot with nVotes entries, each entry is 0 or 1, and all 1-votes are assigned successively.
* A ballot consisting of only zeros is considered valid.
*/
template assertLineVoteVoting(bitsVotes, nVotes) {
    input signal ballot[nVotes];

    component assertBits[nVotes];
    component assertLine = assertBit();

    assertBits[0] = assertBit();
    assertBits[0].in <== ballot[0];

    signal indicator[nVotes];
    indicator[0] <== ballot[0];
    signal tmp[nVotes];


    for(var i = 1; i < nVotes; i++) {
        assertBits[i] = assertBit();
        assertBits[i].in <== ballot[i];

        tmp[i] <== ballot[i] - ballot[i-1];
        indicator[i] <== indicator[i-1] + tmp[i] * ballot[i]; // 1 if there is a change from 0 to 1 from ballot[i-1] to ballot[i], 0 otherwise
    }

    assertLine.in <== indicator[nVotes-1];
}
