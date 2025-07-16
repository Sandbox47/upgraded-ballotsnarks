pragma circom 2.2.1;
include "../utilities/arithmetic.circom";
include "../utilities/branching.circom";
include "../../../libs/node_modules/circomlib/circuits/bitify.circom";

// ========================================================================================================================
// Twisted Edwards points
bus TwistedEdwardsPoint() {
    signal x;
    signal y;
}

template ifThenElseTwistedEdwards() {
    input TwistedEdwardsPoint ifV;
    input TwistedEdwardsPoint elseV;
    input signal cond;

    output TwistedEdwardsPoint out;

    component xIfThenElse = ifThenElse();
    component yIfThenElse = ifThenElse();

    xIfThenElse.ifV <== ifV.x;
    xIfThenElse.elseV <== elseV.x;
    xIfThenElse.cond <== cond;
    yIfThenElse.ifV <== ifV.y;
    yIfThenElse.elseV <== elseV.y;
    yIfThenElse.cond <== cond;

    out.x <== xIfThenElse.out;
    out.y <== yIfThenElse.out;
}

template switchCaseTwistedEdwards(n) {
    input TwistedEdwardsPoint in[n];
    input signal cond[n];

    output TwistedEdwardsPoint out;

    component xSwitchCase = switchCase(n);
    component ySwitchCase = switchCase(n);

    for(var i = 0; i < n-1; i++) {
        xSwitchCase.in[i] <== in[i].x;
        ySwitchCase.in[i] <== in[i].y;
        xSwitchCase.cond[i] <== cond[i];
        ySwitchCase.cond[i] <== cond[i];
    }
    xSwitchCase.in[n-1] <== in[n-1].x;
    ySwitchCase.in[n-1] <== in[n-1].y;
    
    out.x <== xSwitchCase.out;
    out.y <== ySwitchCase.out;
}

template inftyTwistedEdwards() {
    output TwistedEdwardsPoint out;
    out.x <== 0;
    out.y <== 1;
}

// ========================================================================================================================
// Elliptic curve operations

/**
* Computes p1+p2 according to the definition of the group law in "Twisted Edwards Curves" by Bernstein et al./
*
* -> 7 constraints
*/
template twistedEdwardsGroupLaw(a, d) {
    input TwistedEdwardsPoint p1;
    input TwistedEdwardsPoint p2;

    output TwistedEdwardsPoint out;

    component xDivision = division();
    component yDivision = division();

    signal x1y2 <== p1.x * p2.y;
    signal x2y1 <== p2.x * p1.y;
    signal x1x2 <== p1.x * p2.x;
    signal y1y2 <== p1.y * p2.y;
    signal dx1x2y1y2 <== d * x1x2 * y1y2;
    xDivision.numerator <== x1y2 + x2y1;
    xDivision.denominator <== 1 + dx1x2y1y2;
    yDivision.numerator <== y1y2 - a * x1x2;
    yDivision.denominator <== 1 - dx1x2y1y2;

    out.x <== xDivision.out;
    out.y <== yDivision.out;
}

/**
* Computes the m * P, where m=[m_0,m_1,\dots, m_{n-1}] is given as a bitstring in LSB order.
* Furthermore, powersOfP provides [P, 2*P, 4*P, 8*P,\dots, 2^{l-1}*P].
*
* -> 9n-4 Constraints (e.g., 2291 Constraints for n=255)
*/
template twistedEdwardsScalarMul(n, a, d) {
    input TwistedEdwardsPoint powersOfP[n];
    input signal m;

    output TwistedEdwardsPoint out;

    component toBits = Num2Bits(n);
    toBits.in <== m;
    signal mBits[n] <== toBits.out;

    component infty = inftyTwistedEdwards();
    TwistedEdwardsPoint intermediateResults[n+1];
    intermediateResults[0] <== infty.out;
    component adders[n];
    component ifThenElse[n];

    for(var i = 0; i < n; i++) {
        adders[i] = twistedEdwardsGroupLaw(a, d);
        ifThenElse[i] = ifThenElseTwistedEdwards();

        adders[i].p1 <== intermediateResults[i];
        adders[i].p2 <== powersOfP[i];
        ifThenElse[i].ifV <== adders[i].out;
        ifThenElse[i].elseV <== intermediateResults[i];
        ifThenElse[i].cond <== mBits[i];

        intermediateResults[i+1] <== ifThenElse[i].out;
    }

    out <== intermediateResults[n];
}

/**
* Computes the m * P, where m=[m_0,m_1,\dots, m_{n-1}] is given as a representation to base "base" in LSB order. (For brevity, we use b to denote base here)
* Here, m_i = [m_{i,0}, \dots, m_{i,b-1}] is a unary coding of m_i with m_{i,j} = 1 exactly if m_i = j
* Furthermore, powersOfP provides 
*   [   
*       [e, 1*P, 2*1*P,\dots, (b-1)*1*P],
*       [e, b*P, 2*b*P,\dots, (b-1)*b*P],
*       [e, (b^2)*P, 2*(b^2)*P,\dots, (b-1)*(b^2)*P],
*       \dots,
*       [e, (b^{l-1})*P, 2*(b^{l-1})*P,\dots, (b-1)*(b^{n-1})*P]
*   ]
*
* -> Minumum of constraints for base=5
*/
template twistedEdwardsScalarMulArbitraryBase(base, n, a, d) {
    input TwistedEdwardsPoint powersOfP[n][base];
    input signal m[n][base];

    output TwistedEdwardsPoint out;

    component infty = inftyTwistedEdwards();
    TwistedEdwardsPoint intermediateResults[n+1];
    intermediateResults[0] <== infty.out;
    component adders[n];
    component switchCase[n];

    for(var i = 0; i < n; i++) {
        switchCase[i] = switchCaseTwistedEdwards(base);
        adders[i] = twistedEdwardsGroupLaw(a, d);

        switchCase[i].in <== powersOfP[i];
        switchCase[i].cond <== m[i];

        adders[i].p1 <== intermediateResults[i];
        adders[i].p2 <== switchCase[i].out;
        intermediateResults[i+1] <== adders[i].out;
    }

    out <== intermediateResults[n];
}
