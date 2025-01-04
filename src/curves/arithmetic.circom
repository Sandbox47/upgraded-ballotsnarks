pragma circom 2.2.1;

include "branching.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";

/**
* Computes the inverse of an element. Caution, only works if in is invertible.
*/
template invert() {
    signal input in;

    signal output out;

    signal inv <-- 1/in;

    1 === inv*in;
    out <== inv;
}

/**
* Computes numerator/denominator if the denominator is not zero. Caution, only works if denominator is not 0.
*/
template division() {
    signal input numerator;
    signal input denominator;

    signal res;

    signal output out;

    res <-- numerator/denominator;
    numerator === res * denominator;

    out <== res;
}

/**
* Computes numerator/denominator if the denominator is nonzero. Otherwise, computes numerator/1=numerator;
*/
template divisionSafe() {
    signal input numerator;
    signal input denominator;

    signal res;

    signal output out;

    component ifThenElse = ifThenElse();
    component isZero = IsZero();
    isZero.in <== denominator;
    ifThenElse.ifV <== 1;
    ifThenElse.elseV <== denominator;
    ifThenElse.cond <== isZero.out;

    signal fixedDenominator <== ifThenElse.out;

    res <-- numerator/fixedDenominator;
    numerator === res * fixedDenominator;

    out <== res;
}

// component main = divisionSafe();