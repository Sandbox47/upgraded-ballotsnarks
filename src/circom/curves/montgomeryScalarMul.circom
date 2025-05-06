pragma circom 2.2.1;

include "../utilities/branching.circom";
include "../utilities/arithmetic.circom";
include "../utilities/bitify.circom";
include "affinePoint.circom";
include "projectivePoint.circom";
include "conversionsPointRepresentations.circom";
include "montgomeryLadder.circom";
include "yRecovery.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../../../libs/node_modules/circomlib/circuits/gates.circom";
include "../../../libs/node_modules/circomlib/circuits/bitify.circom";

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

    component ladder = ladderProjective(n, A);
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
    component getInfty = inftyProjective();
    component getZero = zeroProjective();

    // Case 1: If P is infty, then mP is also infty.
    component isPInfty = isInftyProjective();
    isPInfty.in <== P;
    signal case0 <== isPInfty.out;
    selectEnabled.s[0] <== case0;
    selectEnabled.in[0] <== getInfty.out;

    // Case 2: If P is zero and the exponent is odd, then the output is zero.
    component isPZero = isZeroProjective();
    isPZero.in <== P;
    signal ismOdd <== mBits[0];
    signal case1 <== isPZero.out * ismOdd;
    selectEnabled.s[1] <== case1;
    selectEnabled.in[1] <== getZero.out;

    // Case 3: If P is zero and the exponent is even, then the output is infty.
    signal case2 <== isPZero.out * (1-ismOdd);
    selectEnabled.s[2] <== case2;
    selectEnabled.in[2] <== getInfty.out;

    // Case 4: Otherwise, the result mPReconstructed is correct.
    signal tmp <== (1-case1) * (1-case2);
    signal case3 <== tmp * (1-case0);
    selectEnabled.s[3] <== case3;
    selectEnabled.in[3] <== mPReconstructed;

    out <== selectEnabled.out;

    // Test:
    // input ProjectivePoint() test;
    // test === out;
}
