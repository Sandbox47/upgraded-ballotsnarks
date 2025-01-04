pragma circom 2.2.1;

include "../../libs/node_modules/circomlib/circuits/gates.circom";
/**
* Numbers are generally stored in MSB to LSB order. E.g., 11 = [1, 0, 1, 1]
*/


template HalfAdder() {
    signal input x;
    signal input y;

    signal output s;
    signal output c;

    // signal input v_s;
    // signal input v_c;

    component xor = XOR();
    component and = AND();

    xor.a <== x;
    xor.b <== y;

    and.a <== x;
    and.b <== y;

    s <== xor.out;
    c <== and.out;

    // v_s === s;
    // v_c === c;
}

template FullAdder() {
    signal input c_in;
    signal input x;
    signal input y;

    // signal input v_s;
    // signal input v_c;

    signal output c_out;
    signal output s;

    component ha_1 = HalfAdder();
    component ha_2 = HalfAdder();
    component or = OR();

    ha_1.x <== x;
    ha_1.y <== y;

    ha_2.x <== ha_1.s;
    ha_2.y <== c_in;

    or.a <== ha_1.c;
    or.b <== ha_2.c;
    
    s <== ha_2.s;
    c_out <== or.out;

    // v_s === s;
    // v_c === c_out;
}

/**
* Creates a zero signal of size n.
*/
template Zero(n) {
    signal output out[n];

    for(var i = 0; i < n; i++) {
        out[i] <== 0;
    }
}


template BinAdd(n) {
    signal input x[n];
    signal input y[n];

    signal output s[n+1];

    component fas[n];
    fas[0] = FullAdder();
    fas[0].c_in <== 0;
    fas[0].x <== x[0];
    fas[0].y <== y[0];
    s[0] <== fas[0].s;

    for(var i = 1; i < n; i++) {
        fas[i] = FullAdder();
        fas[i].c_in <== fas[i-1].c_out;
        fas[i].x <== x[i];
        fas[i].y <== y[i];
        s[i] <== fas[i].s;
    }
    s[n] <== fas[n-1].c_out;
}

/**
* Shifts the bits in x to the left by k places by adding a zero bits to the right.
*/
template BinLeftShift(n, k) {
    signal input x[n];

    signal output ls[n+k];

    for(var i = 0; i < n; i++) {
        ls[i] <== x[i];
    }
    for(var i = n; i < n+k; i++) {
        ls[i] <== 0;
    }
}

/**
* Shifts the bits in x to the right by k places by removing the right most bits.
*/
template BinRightShift(n, k) {
    signal input x[n];

    signal output rs[n-1];

    for(var i = 0; i < n-k; i++) {
        rs[i] <== x[n];
    }
}

/**
* Extends x to the left with k zeros.
*/
template BinZeroPaddingLeft(n, k) {
    signal input x[n];

    signal output padded[n+k];

    for(var i = 0; i < k; i++) {
        padded[i] <== 0;
    }
    for(var i = 0; i < n; i++) {
        padded[i+k] <== x[i];
    }
}


/**
* Computes b*x for a bit b and a number x.
*/
template BinMulBit(n) {
    signal input x[n];
    signal input b;

    signal output m[n];

    component ands[n];

    for(var i = 0; i < n; i++) {
        ands[i] = AND();
        ands[i].a <== x[i];
        ands[i].b <== b;
        m[i] <== ands[i].out;
    }
}

/**
* Computes m = x*y.
*/
template BinMul(n) {
    signal input x[n];
    signal input y[n];

    signal output m[2*n];

    component add[n+1];
    component mulBits[n];
    component leftShift[n];
    component pad[n];
    component zero = Zero(n-1);

    add[0] = BinAdd(n-1);
    add[0].x <== zero.out;
    add[0].y <== zero.out;

    for(var i = 0; i < n; i++) {
        add[i+1] = BinAdd(n+i);
        mulBits[i] = BinMulBit(n);
        leftShift[i] = BinLeftShift(n, i);

        mulBits[i].x <== x;
        mulBits[i].b <== y[n-i-1];
        leftShift[i].x <== mulBits[i].m;
        add[i+1].x <== add[i].s;
        add[i+1].y <== leftShift[i].ls;
    }
    m <== add[n].s;
}

/**
* To compute q and r that satisfy x = q*y + r;
*/
// template DivMod(n, m) {
//     signal input x[n];
//     signal input y[m];
// 
// 
// 
// 
// 
// }
// 
// template ModQ(n, m) {
//     signal input q[n];
//     signal input x[m];
// 
// 
// 
//     signal output out[n];
// 
// }

// template BaseQAdd(n) {
//     signal input q[n];
//     signal input x[n];
//     signal input y[n];
// 
// 
// 
// }
// 
// template BaseQSub() {
// 
// }
// 
// template BaseQMul() {
// 
// }
// 
// template BaseQDiv() {
// 
// }

component main = BinMul(256);