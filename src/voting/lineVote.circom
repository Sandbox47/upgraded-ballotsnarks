pragma circom 2.2.1;

include "../utilities/asserts.circom";

/**
* Asserts that in a ballot with n entries, each entry is 0 or 1, and all 1-votes are assigned successively.
* A ballot consisting of only zeros is considered valid.
*/
template assertLineVote(n) {
    input signal ballot[n];

    component assertBits[n];
    component assertLine = assertBit();

    assertBits[0] = assertBit();
    assertBits[0].in <== ballot[0];

    signal indicator[n];
    indicator[0] <== ballot[0];
    signal tmp[n];


    for(var i = 1; i < n; i++) {
        assertBits[i] = assertBit();
        assertBits[i].in <== ballot[i];

        tmp[i] <== ballot[i] - ballot[i-1];
        indicator[i] <== indicator[i-1] + tmp[i] * ballot[i]; // 1 if there is a change from 0 to 1 from ballot[i-1] to ballot[i], 0 otherwise
    }

    assertLine.in <== indicator[n-1];
}

component main = assertLineVote(100);