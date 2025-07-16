pragma circom 2.2.1;

include "../curves/affinePoint.circom";
include "../curves/projectivePoint.circom";
include "../curves/conversionsPointRepresentations.circom";
include "../curves/montgomeryScalarMul.circom";
include "../curves/montgomeryGroupLaw.circom";
include "../curves/twistedEdwardsCurve.circom";

// ========================================================================================================================
// MONTGOMERY

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve.
* 
* For given generator g, public key pk, plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of bits r and v can have at most.
*/
template expElGamalMontgomeryProjective(bitsRand, bitsPlain, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v; // Plaintext
    input signal r; // Randomness

    output ProjectivePoint() gr; // g^r
    output ProjectivePoint() gv_pkr; // g^v * pk^r

    component scalarMul_gv = scalarMulProjective(bitsPlain, A, B);
    scalarMul_gv.m <== v;
    scalarMul_gv.P <== g;
    ProjectivePoint() gv <== scalarMul_gv.out; // g^v

    component scalarMul_pkr = scalarMulProjective(bitsRand, A, B);
    scalarMul_pkr.m <== r;
    scalarMul_pkr.P <== pk;
    ProjectivePoint() pkr <== scalarMul_pkr.out; // pk^r

    component scalarMul_gr = scalarMulProjective(bitsRand, A, B);
    scalarMul_gr.m <== r;
    scalarMul_gr.P <== g;
    gr <== scalarMul_gr.out;

    component add_gv_pkr = addProjective(A, B);
    add_gv_pkr.P <== gv;
    add_gv_pkr.Q <== pkr;
    gv_pkr <== add_gv_pkr.out;
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve.
* 
* For given generator g, public key pk, plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of bits r and v can have at most.
*/
template expElGamalMontgomeryAffine(bitsRand, bitsPlain, A, B) {
    input AffinePoint() g; // Generator
    input AffinePoint() pk; // Public key, pk=g^b for some private b
    input signal v; // Plaintext
    input signal r; // Randomness

    output AffinePoint() gr; // g^r
    output AffinePoint() gv_pkr; // g^v * pk^r

    component convertToProjective_g = affineToProjective();
    component convertToProjective_pk = affineToProjective();
    convertToProjective_g.in <== g;
    convertToProjective_pk.in <== pk;

    component expElGamalMontgomeryProjective = expElGamalMontgomeryProjective(bitsRand, bitsPlain, A, B);
    expElGamalMontgomeryProjective.g <== convertToProjective_g.out;
    expElGamalMontgomeryProjective.pk <== convertToProjective_pk.out;
    expElGamalMontgomeryProjective.v <== v;
    expElGamalMontgomeryProjective.r <== r;

    component convertToAffine_gr = projectiveToAffine();
    component convertToAffine_gv_pkr = projectiveToAffine();
    convertToAffine_gr.in <== expElGamalMontgomeryProjective.gr;
    convertToAffine_gv_pkr.in <== expElGamalMontgomeryProjective.gv_pkr;

    gr <== convertToAffine_gr.out;
    gv_pkr <== convertToAffine_gv_pkr.out;
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve for each of the given inputs v with corresponding randomnesses r.
* 
* entires is the number of entries in the vector to be encrypted.
*/
template expElGamalVectorMontgomeryProjective(bitsRand, bitsPlain, A, B, entries) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[entries]; // Signal
    input signal r[entries]; // Randomness

    output ProjectivePoint() gr[entries];
    output ProjectivePoint() gv_pkr[entries];

    component expElGamal[entries];

    for(var i = 0; i < entries; i++) {
        expElGamal[i] = expElGamalMontgomeryProjective(bitsRand, bitsPlain, A, B);
        expElGamal[i].g <== g;
        expElGamal[i].pk <== pk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve for each of the given inputs v with corresponding randomnesses r.
* 
* rows and columns are the number of rows and columns in the matrix of entries to be encrypted.
*/
template expElGamalMatrixMontgomeryProjective(bitsRand, bitsPlain, A, B, rows, columns) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[rows][columns]; // Signal
    input signal r[rows][columns]; // Randomness

    output ProjectivePoint() gr[rows][columns];
    output ProjectivePoint() gv_pkr[rows][columns];

    component expElGamal[rows];

    for(var i = 0; i < rows; i++) {
        expElGamal[i] = expElGamalVectorMontgomeryProjective(bitsRand, bitsPlain, A, B, columns);
        expElGamal[i].g <== g;
        expElGamal[i].pk <== pk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

// ========================================================================================================================
// TWISTED EDWARDS

/**
* Computes an exponential ElGamal ciphertext over a Twisted Edwards curve.
* 
* For given powers of a generator [g^1,g^2,g^4,...,g^{2^{bitsRand-1}}], powers of a public key [pk^1,pk^2,pk^4, ..., pk^{2^{bitsRand-1}}], plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of bits r and v can have at most.
*/
template expElGamalTwistedEdwards(bitsRand, bitsPlain, a, d) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v; // Plaintext
    input signal r; // Randomness

    output TwistedEdwardsPoint() gr; // g^r
    output TwistedEdwardsPoint() gv_pkr; // g^v * pk^r

    component scalarMul_gv = twistedEdwardsScalarMul(bitsPlain, a, d);
    scalarMul_gv.m <== v;
    for(var i = 0; i < bitsPlain; i++) {
        scalarMul_gv.powersOfP[i] <== powersOfg[i];
    }
    TwistedEdwardsPoint() gv <== scalarMul_gv.out; // g^v

    component scalarMul_pkr = twistedEdwardsScalarMul(bitsRand, a, d);
    scalarMul_pkr.m <== r;
    scalarMul_pkr.powersOfP <== powersOfpk;
    TwistedEdwardsPoint() pkr <== scalarMul_pkr.out; // pk^r

    component scalarMul_gr = twistedEdwardsScalarMul(bitsRand, a, d);
    scalarMul_gr.m <== r;
    scalarMul_gr.powersOfP <== powersOfg;
    gr <== scalarMul_gr.out;

    component add_gv_pkr = twistedEdwardsGroupLaw(a, d);
    add_gv_pkr.p1 <== gv;
    add_gv_pkr.p2 <== pkr;
    gv_pkr <== add_gv_pkr.out;
}

/**
* Computes an exponential ElGamal ciphertext over a Twisted Edwards curve for each of the given inputs v with corresponding randomnesses r.
* 
* entires is the number of entries in the vector to be encrypted.
*/
template expElGamalVectorTwistedEdwards(bitsRand, bitsPlain, a, d, entries) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v[entries]; // Signal
    input signal r[entries]; // Randomness

    output TwistedEdwardsPoint() gr[entries];
    output TwistedEdwardsPoint() gv_pkr[entries];

    component expElGamal[entries];

    for(var i = 0; i < entries; i++) {
        expElGamal[i] = expElGamalTwistedEdwards(bitsRand, bitsPlain, a, d);
        expElGamal[i].powersOfg <== powersOfg;
        expElGamal[i].powersOfpk <== powersOfpk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve for each of the given inputs v with corresponding randomnesses r.
* 
* rows and columns are the number of rows and columns in the matrix of entries to be encrypted.
*/
template expElGamalMatrixTwistedEdwards(bitsRand, bitsPlain, a, d, rows, columns) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v[rows][columns]; // Signal
    input signal r[rows][columns]; // Randomness

    output TwistedEdwardsPoint() gr[rows][columns];
    output TwistedEdwardsPoint() gv_pkr[rows][columns];

    component expElGamal[rows];

    for(var i = 0; i < rows; i++) {
        expElGamal[i] = expElGamalVectorTwistedEdwards(bitsRand, bitsPlain, a, d, columns);
        expElGamal[i].powersOfg <== powersOfg;
        expElGamal[i].powersOfpk <== powersOfpk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

// ========================================================================================================================
// TWISTED EDWARDS with arbitrary base

/**
* Computes an exponential ElGamal ciphertext over a Twisted Edwards curve using base "base" to represent the randomness and the value to be encrypted. (For brevity, we use b to denote base here)
* 
* For given powers of a generator g
*   [   
*       [e, 1*g, 2*1*g,\dots, (b-1)*1*g],
*       [e, b*g, 2*b*g,\dots, (b-1)*b*g],
*       [e, (b^2)*g, 2*(b^2)*g,\dots, (b-1)*(b^2)*g],
*       \dots,
*       [e, (b^{l-1})*g, 2*(b^{l-1})*g,\dots, (b-1)*(b^{n-1})*g]
*   ],
* powers of a public key of the same format, plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* Here, we are using v and r in the following representation:
*   v=[v_0,v_1,\dots, v_{n-1}] is given as a representation to base "base" in LSB order.
*   Here, v_i = [v_{i,0}, \dots, v_{i,b-1}] is a unary coding of v_i with v_{i,j} = 1 exactly if v_i = j
* 
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of "bits" r and v can have at most.
*/
template expElGamalTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d) {
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[bitsPlain][base]; // Plaintext
    input signal r[bitsRand][base]; // Randomness

    output TwistedEdwardsPoint() gr; // g^r
    output TwistedEdwardsPoint() gv_pkr; // g^v * pk^r

    component scalarMul_gv = twistedEdwardsScalarMulArbitraryBase(base, bitsPlain, a, d);
    scalarMul_gv.m <== v;
    for(var i = 0; i < bitsPlain; i++) {
        scalarMul_gv.powersOfP[i] <== powersOfg[i];
    }
    TwistedEdwardsPoint() gv <== scalarMul_gv.out; // g^v

    component scalarMul_pkr = twistedEdwardsScalarMulArbitraryBase(base, bitsRand, a, d);
    scalarMul_pkr.m <== r;
    scalarMul_pkr.powersOfP <== powersOfpk;
    TwistedEdwardsPoint() pkr <== scalarMul_pkr.out; // pk^r

    component scalarMul_gr = twistedEdwardsScalarMulArbitraryBase(base, bitsRand, a, d);
    scalarMul_gr.m <== r;
    scalarMul_gr.powersOfP <== powersOfg;
    gr <== scalarMul_gr.out;

    component add_gv_pkr = twistedEdwardsGroupLaw(a, d);
    add_gv_pkr.p1 <== gv;
    add_gv_pkr.p2 <== pkr;
    gv_pkr <== add_gv_pkr.out;
}

/**
* Computes an exponential ElGamal ciphertext over a Twisted Edwards curve for each of the given inputs v with corresponding randomnesses r.
* 
* entires is the number of entries in the vector to be encrypted.
*/
template expElGamalVectorTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d, entries) {
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[entries][bitsPlain][base]; // Plaintext
    input signal r[entries][bitsRand][base]; // Randomness

    output TwistedEdwardsPoint() gr[entries];
    output TwistedEdwardsPoint() gv_pkr[entries];

    component expElGamal[entries];

    for(var i = 0; i < entries; i++) {
        expElGamal[i] = expElGamalTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d);
        expElGamal[i].powersOfg <== powersOfg;
        expElGamal[i].powersOfpk <== powersOfpk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve for each of the given inputs v with corresponding randomnesses r.
* 
* rows and columns are the number of rows and columns in the matrix of entries to be encrypted.
*/
template expElGamalMatrixTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d, rows, columns) {
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[rows][columns][bitsPlain][base]; // Plaintext
    input signal r[rows][columns][bitsRand][base]; // Randomness

    output TwistedEdwardsPoint() gr[rows][columns];
    output TwistedEdwardsPoint() gv_pkr[rows][columns];

    component expElGamal[rows];

    for(var i = 0; i < rows; i++) {
        expElGamal[i] = expElGamalVectorTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d, columns);
        expElGamal[i].powersOfg <== powersOfg;
        expElGamal[i].powersOfpk <== powersOfpk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}
