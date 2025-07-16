pragma circom 2.2.1;
include "arithmetic.circom";
include "branching.circom";
include "../../../libs/node_modules/circomlib/circuits/bitify.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";

/**
* Converts the number in to binary representation (LSB) and padds the representation with 2 to extend it to length n.
* Note, the first Non-zero bit from the end of the binary representation will also be set to 2. 
* This is needed for the montgomery scalar multiplication.
*/
template num2BitsPadded(n) {
    input signal in;

    output signal out[n];

    component toBits = Num2Bits(n);
    toBits.in <== in;
    signal inBits[n] <== toBits.out;

    component padBits = padBits(n);
    padBits.in <== inBits;
    out <== padBits.out;
}

/**
* For a number in to binary representation (LSB): Padds the representation with 2 to extend it to length n.
* Note, the first Non-zero bit from the end of the binary representation will also be set to 2. 
* This is needed for the montgomery scalar multiplication (in one of the implemented options).
*/
template padBits(n) {
    input signal in[n];

    output signal out[n];

    component setPadding[n];
    component needsPadding[n];

    signal sumBits[n+1];
    sumBits[n] <== 0;
    for(var i = n-1; i >= 0; i--) {
        sumBits[i] <== sumBits[i+1] + in[i];

        setPadding[i] = ifThenElse();
        needsPadding[i] = IsZero();

        needsPadding[i].in <== sumBits[i+1]; //First Non-zero Bit is also set to 2.

        setPadding[i].ifV <== 2; //Padding 2 for trailing zeros.
        setPadding[i].elseV <== in[i];
        setPadding[i].cond <== needsPadding[i].out;

        out[i] <== setPadding[i].out;
    }  
}