pragma circom 2.2.1;

include "../utilities/asserts.circom";

/**
* Assert that in a ballot with n votes, each vote is 0 or one and that exactly one vote is one.
*/
template assertSingleVote(n) {
    input signal ballot[n];

    component assertBit[n];
    component assertSumBit = assertBit();

    var sum = 0;

    for(var i = 0; i < n; i++) {
        assertBit[i] = assertBit();
        assertBit[i].in <== ballot[i];
        sum += ballot[i];
    }

    assertSumBit.in <== sum;
}

// component main = assertSingleVote(100);