pragma circom 2.2.1;

include "../utilities/branching.circom";
include "../utilities/arithmetic.circom";
include "../utilities/bitify.circom";
include "affinePoint.circom";
include "projectivePoint.circom";
include "conversionsPointRepresentations.circom";
include "montgomeryLadder.circom";
include "yRecovery.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../../libs/node_modules/circomlib/circuits/gates.circom";
include "../../libs/node_modules/circomlib/circuits/bitify.circom";

// ========================================================================================================================
// SCALAR MULTIPLICATION

/**
* Computes mP. (Where m is later represented as a bit string of length n.)
*/
template scalarMulAffine(n, A, B) {
    input signal m;
    input AffinePoint() P;

    output AffinePoint() out;

    component convertToProjective = affineToProjective();
    convertToProjective.in <== P;
    ProjectivePoint() projectiveP <== convertToProjective.out;

    component scalarMulProjective = scalarMulProjective(n, A, B);
    scalarMulProjective.m <== m;
    scalarMulProjective.P <== projectiveP;

    component convertToAffine = projectiveToAffine();
    convertToAffine.in <== scalarMulProjective.out;
    out <== convertToAffine.out;

    // log("\nFinal result:");
    // log("x: ", out.x);
    // log("y: ", out.y);
    // log("notInfty: ", out.notInfty);

    // Test:
    input AffinePoint() test;
    test === out;
}

/**
* Computes mP. (Where m is later represented as a bit string of length n.)
*/
template scalarMulProjective(n, A, B) {
    input signal m;
    input ProjectivePoint() P;

    output ProjectivePoint() out;

    component toBits = Num2Bits(n);
    toBits.in <== m;
    signal mBits[n] <== toBits.out;
    // log("Multiplier:");
    // log(m);
    // log("Individual Bits (Least significant Bit first):");
    // for(var i = 0; i < n; i++) {
    //     log(mBits[i]);
    // }

    component ladder = ladderProjective(n, A);
    // component ladder = ladderProjectivePaddedNaive(n, A);
    // component ladder = ladderProjectivePaddedConstraintReduced(n, A);
    ladder.mulBits <== mBits;
    ladder.P <== P;
    ProjectivePoint() mP <== ladder.r0Final;
    ProjectivePoint() mPlus1P <== ladder.r1Final;

    component yRecovery = yRecoveryProjective(A, B);
    yRecovery.P <== P;
    yRecovery.Q <== mP;
    yRecovery.PPlusQ <== mPlus1P;

    ProjectivePoint() mPReconstructed <== yRecovery.out;

    component selectEnabled = selectEnabledProjective(4);
    // component switchCase = switchCaseProjective(4);
    component getInfty = inftyProjective();
    component getZero = zeroProjective();

    // Case 1: If P is infty, then mP is also infty.
    component isPInfty = isInftyProjective();
    isPInfty.in <== P;
    signal case0 <== isPInfty.out;
    selectEnabled.s[0] <== case0;
    selectEnabled.in[0] <== getInfty.out;
    // switchCase.cond[0] <== case0;
    // switchCase.in[0] <== getInfty.out;

    // Case 2: If P is zero and the exponent is odd, then the output is zero.
    component isPZero = isZeroProjective();
    isPZero.in <== P;
    signal ismOdd <== mBits[0];
    signal case1 <== isPZero.out * ismOdd;
    selectEnabled.s[1] <== case1;
    selectEnabled.in[1] <== getZero.out;
    // switchCase.cond[1] <== case1;
    // switchCase.in[1] <== getZero.out;

    // Case 3: If P is zero and the exponent is even, then the output is infty.
    signal case2 <== isPZero.out * (1-ismOdd);
    selectEnabled.s[2] <== case2;
    selectEnabled.in[2] <== getInfty.out;
    // switchCase.cond[2] <== case2;
    // switchCase.in[2] <== getInfty.out;

    // Case 4: Otherwise, the result mPReconstructed is correct.
    signal tmp <== (1-case1) * (1-case2);
    signal case3 <== tmp * (1-case0);
    selectEnabled.s[3] <== case3;
    selectEnabled.in[3] <== mPReconstructed;
    // switchCase.in[3] <== mPReconstructed;

    // log("\nChosen case:");
    // log(case0, case1, case2);

    out <== selectEnabled.out;
    // out <== switchCase.out;

    // Test:
    // input ProjectivePoint() test;
    // test === out;
}

/**
* Computes mP. (Where m is later represented as a bit string of length n.
* Needs powers of P of the form [P, 2P, 4P, 8P, ..., (2^n)P].
* CAUTION: Only works if m > 0
*/
/*
template scalarMulProjectivePrecomputedExponents(n, A, B) {
    input signal m;
    input ProjectivePoint() powersOfP[n]; //

    output ProjectivePoint() out;

    component toBits = Num2Bits(n);
    toBits.in <== m;
    signal mBits[n] <== toBits.out;

    component adders[n];
    component 

    signal intermediateResults[n];
    signal intermediateResults[0] <== powersOfP[0];
    for(var i = 1; i < n; i++) {
        intermediateResults[i] <== 
    }

    intermediateResults[0] <== powersOfP[0]
}
*/

// component main = scalarMulProjective(32, 126932, 1);
// component main = scalarMulAffine(255, 126932, 1);