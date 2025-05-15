pragma circom 2.2.1;

include "../utilities/branching.circom";
include "../utilities/arithmetic.circom";
include "affinePoint.circom";
include "projectivePoint.circom";
include "conversionsPointRepresentations.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";

// ========================================================================================================================
// GROUP LAW CASES:

template tangentRuleAffine(A, B) {
    input AffinePoint() p;

    output AffinePoint() out;

    signal xx <== p.x*p.x;
    component division = divisionSafe();
    division.numerator <== 3*xx + 2*A*p.x + 1;
    division.denominator <== 2*B*p.y;
    signal fractionSq <== division.out*division.out;
    out.x <== fractionSq*B - 2*p.x - A;

    signal xDif <== p.x-out.x;
    out.y <== division.out*xDif - p.y;

    out.notInfty <== 1;
}

template chordRuleAffine(A, B) {
    input AffinePoint() p;
    input AffinePoint() q;

    output AffinePoint() out;

    component division = divisionSafe();
    division.numerator <== q.y - p.y;
    division.denominator <== q.x - p.x;
    signal fractionSq <== division.out*division.out;
    out.x <== fractionSq*B - (p.x + q.x) - A;

    signal xDif <== p.x-out.x;
    out.y <== division.out*xDif - p.y;

    out.notInfty <== 1;
}

// ========================================================================================================================
// GROUP LAW:

/**
* Implements the addition of two points given in affine representation. (Using the group law as presented in MoonMath, 5.2)
*/
template addAffine(A, B) {
    input AffinePoint() p;
    input AffinePoint() q;

    output AffinePoint() out;

    component groupLawCases = switchCaseAffine(4);
    component serializep = serializeAffine();
    component serializeq = serializeAffine();
    serializep.in <== p;
    serializeq.in <== q;

    signal selector[3]; // Selects which of the cases of the group law to take.
    AffinePoint() cases[4]; //The result of the group law in the different cases.

    selector[0] <== 1 - p.notInfty*q.notInfty; // If one of the points is infty, we need to output the other as the result
    component deserialize = deserializeAffine();
    component ifPInftyThenQElseP = ifThenElseMulti(3);
    ifPInftyThenQElseP.cond <== 1-p.notInfty;
    ifPInftyThenQElseP.ifV <== serializeq.out;
    ifPInftyThenQElseP.elseV <== serializep.out;
    deserialize.in <== ifPInftyThenQElseP.out;
    cases[0] <== deserialize.out;

    component isNegation = IsZero();
    isNegation.in <== p.y+q.y;
    selector[1] <== (1-selector[0])*isNegation.out; // If not Case 1 and the y coordiantes are negations of each other, we need to output infty as the result.
    component infty = inftyAffine();
    cases[1] <== infty.out;

    component equalsx = IsZero();
    component equalsy = IsZero();
    equalsx.in <== p.x-q.x;
    equalsy.in <== p.y-q.y;
    signal equals <== equalsx.out * equalsy.out;
    signal selectorNot01 <== (1-selector[1])*(1-selector[0]);
    selector[2] <== selectorNot01*equals; // If the points are the same, we need to apply the tangent rule;
    component tangentRule = tangentRuleAffine(A, B);
    tangentRule.p <== p;
    cases[2] <== tangentRule.out;

    component chordRule = chordRuleAffine(A, B);
    chordRule.p <== p;
    chordRule.q <== q;
    cases[3] <== chordRule.out;

    groupLawCases.in <== cases;
    groupLawCases.cond <== selector;

    out <== groupLawCases.out;

    // Test:
    // input AffinePoint() test;
    // out === test;
}

template addProjective(A, B) {
    input ProjectivePoint() P;
    input ProjectivePoint() Q;

    output ProjectivePoint() out;

    component convertToAffineP = projectiveToAffine();
    component convertToAffineQ = projectiveToAffine();
    component affineAdder = addAffine(A, B);
    component convertToProjectiveRes = affineToProjective();

    convertToAffineP.in <== P;
    convertToAffineQ.in <== Q;

    affineAdder.p <== convertToAffineP.out;
    affineAdder.q <== convertToAffineQ.out;

    convertToProjectiveRes.in <== affineAdder.out;
    out <== convertToProjectiveRes.out;

    // Test:
    // input ProjectivePoint() test;
    // out === test;
}
