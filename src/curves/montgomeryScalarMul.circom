pragma circom 2.2.1;

include "../utilities/branching.circom";
include "../utilities/arithmetic.circom";
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
}


// ========================================================================================================================
// TESTS:
/* Add affine chord rule test:
    Input points:
    p = (20350112980332495410491806106641912032405807740206955641061065374486698796317, 14802660259816080277511375667429496994814855765153723011254359800269211103660, 1)
    q = (6436550625859115314273341999431281045921882911473785275445591016670213976054, 4911560927196046703381769182402726179096272710280490153721015398415972676297, 1)
    Expected Output:
    out = (7306455872859196908558943217263429454398369715445672625861646916000069222142, 5168193925279556701056169608834112308914330031216789481129608101247302645921, 1)
*/
/* Add affine tangent rule test:
    Input points:
    p = q = (4118539398467926584682657566310407557795734099513828559961124542414074202229, 13695552684664363390493079180907196421930367647106528160692950450717086983669, 1)
    Expected Output:
    out = (13191020427819135497375733108775087671420687347105010986864076588002895255680, 14872857448681080766454952069697763630820526668319493378835763128018307235081, 1)
*/
/* Add affine infty test:
    Input points:
    p = (4118539398467926584682657566310407557795734099513828559961124542414074202229, 13695552684664363390493079180907196421930367647106528160692950450717086983669, 1)
    q = (0, 0, 0)
    Expected Output:
    out = p
*/
/* Add affine points with negated y coords test:
    Input points:
    p = (9869126941026947411437539396088279291493067976498332851790420256883651976887, 12375405827046910722190572009046646300838204184475632032483724651981872733461, 1)
    q = (9869126941026947411437539396088279291493067976498332851790420256883651976887, 9512837044792364500055833736210628787710160215940402311214479534593935762156, 1)
    Expected Output:
    out = (0, 0, 0)
*/

// component main = addAffine(126932,1);
// component main = ladderProjective(256, 12632);
// component main = scalarMulAffine(256, 126932, 1);