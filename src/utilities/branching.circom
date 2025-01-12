pragma circom 2.2.1;
include "arithmetic.circom";
include "../../libs/node_modules/circomlib/circuits/mux2.circom";
include "../../libs/node_modules/circomlib/circuits/bitify.circom";

/**
* If "cond" is 1, the output will be "ifV", otherwise the result will be "elseV"
*/
template ifThenElse() {
    signal input ifV;
    signal input elseV;
    signal input cond;

    signal output out;

    signal condIfV <== cond * ifV;

    out <== condIfV + (1-cond)*elseV;
}

/**
* If "cond" is 1, the output will be "ifV", otherwise the result will be "elseV"
*/
template ifThenElseMulti(n) {
    signal input ifV[n];
    signal input elseV[n];
    signal input cond;

    signal output out[n];
    signal condIfV[n];

    for(var i = 0; i < n; i++) {
        condIfV[i] <== cond * ifV[i];
        out[i] <== condIfV[i] + (1-cond)*elseV[i];
    }
}

/**
* If "cond" is 1, the output will be 0, otherwise the result will be "in"
*/
template ifThenSetZero() {
    signal input in;
    signal input cond;

    signal output out;

    out <== (1-cond)*in;
}

/**
* If "in" is 0, out will also be 0, otherwise out will be 1.
*/
template constrainToBin() {
    signal input in;

    signal output out;

    component ifThenElse = ifThenElse();

    ifThenElse.cond <== 1-in;
    ifThenElse.ifV <== 0;
    ifThenElse.elseV <== 1;

    out <== ifThenElse.out;
}

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
* Selects the input based on the s-signals. Only works, if one of the s-signals is 1 and all others are zero.
*/
template selectEnabledMulti(n, m) {
    signal input in[n][m];
    signal input s[n];

    signal output out[m];

    signal tmp[n][m];
    var sums[m];
    for(var j= 0; j < m; j++) {
        sums[j] = 0;
    }
    for(var i = 0; i < n; i++) {
        for(var j = 0; j < m; j++) {
            tmp[i][j] <== s[i]*in[i][j];
            sums[j] += tmp[i][j];
        }
    }
    out <== sums;
}

/**
* Selects the input based on the selector signal (the selector signal can be 0, 1, 2 or 3 (2 Bits)).
* (Uses the selector signal as index for the input array.)
*/
template mux2() {
    input signal selector;
    input signal in[4];

    output signal out;

    component toBits = Num2Bits(2);
    toBits.in <== selector;
    component mux2 = Mux2();
    mux2.c <== in;
    mux2.s <== toBits.out;
    
    out <== mux2.out;
}

/**
* Selects the inputs based on the selector signal (the selector signal can be 0, 1, 2 or 3 (2 Bits)).
* (Uses the selector signal as index for each of the input array.)
*/
template muxMulti2(n) {
    input signal selector;
    input signal in[4][n];

    output signal out[n];

    component toBits = Num2Bits(2);
    toBits.in <== selector;

    component mux2 = MultiMux2(n);
    for(var i = 0; i < n; i++) {
        for(var j = 0; j < 4; j++){
            mux2.c[i][j] <== in[j][i];
        }
    }
    mux2.s <== toBits.out;
    
    out <== mux2.out;
}

// component main = selectEnabled(16);
