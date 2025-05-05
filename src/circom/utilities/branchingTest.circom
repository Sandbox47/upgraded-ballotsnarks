pragma circom 2.2.1;
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";

/**
* Selects the input based on the s-signals. Only works, if one of the s-signals is 1 and all others are zero.
*/
template selectEnabled(n) {
    signal input in[n];
    signal input s[n];

    signal output out;

    signal tmp[n];
    var sum = 0;
    for(var i = 0; i < n; i++) {
        tmp[i] <== s[i]*in[i];
        sum += tmp[i];
    }
    out <== sum;
}

/**
* Selects the entry which index is selector from the in.
*/
template mux(n) {
    input signal selector;
    input signal in[n];

    output signal out;

    component caseI[n];
    component selectEnabled = selectEnabled(n);
    selectEnabled.in <== in;

    for(var i = 0; i < n; i++) {
        caseI[i] = IsEqual();
        caseI[i].in[0] <== i;
        caseI[i].in[1] <== selector;
        selectEnabled.s[i] <== caseI[i].out;
    }

    out <== selectEnabled.out;
}

// component main = mux(3);
