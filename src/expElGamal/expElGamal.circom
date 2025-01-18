pragma circom 2.2.1;

include "../curves/affinePoint.circom";
include "../curves/projectivePoint.circom";
include "../curves/conversionsPointRepresentations.circom";
include "../curves/montgomeryScalarMul.circom";
include "../curves/montgomeryGroupLaw.circom";

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve.
* 
* For given generator g, public key pk, plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of bits r and v can have at most.
*
* TODO: Can I limit the numer of bits in r?
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

    // Test:
    // input ProjectivePoint() test_gr;
    // input ProjectivePoint() test_gv_pkr;
    // gr === test_gr;
    // gv_pkr === test_gv_pkr;
}

/**
* Computes an exponential ElGamal ciphertext over a Montgomery curve.
* 
* For given generator g, public key pk, plaintext v and randomness r, the ciphertext is (g^r, g^v*pk^r)
* NOTE: We are now switching from additive to multiplicative notation for the application of the Montgomery group law.
* 
* bitsRand and bitsPlain are the number of bits r and v can have at most.
*
* TODO: Can I limit the numer of bits in r?
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
template expElGamalVector(bitsRand, bitsPlain, A, B, entries) {
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
template expElGamalMatrix(bitsRand, bitsPlain, A, B, rows, columns) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[rows][columns]; // Signal
    input signal r[rows][columns]; // Randomness

    output ProjectivePoint() gr[rows][columns];
    output ProjectivePoint() gv_pkr[rows][columns];

    component expElGamal[rows];

    for(var i = 0; i < rows; i++) {
        expElGamal[i] = expElGamalVector(bitsRand, bitsPlain, A, B, columns);
        expElGamal[i].g <== g;
        expElGamal[i].pk <== pk;
        expElGamal[i].v <== v[i];
        expElGamal[i].r <== r[i];
        gr[i] <== expElGamal[i].gr;
        gv_pkr[i] <== expElGamal[i].gv_pkr;
    }
}

// component main = expElGamalMontgomeryProjective(255, 32, 126932, 1);
// component main = expElGamalVector(255, 32, 126932, 1, 100);
// component main = expElGamalMatrix(255, 32, 126932, 1, 10, 10);