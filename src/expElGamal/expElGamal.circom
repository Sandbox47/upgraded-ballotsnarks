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
*/
template expElGamalMontgomeryProjective(n, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v; // Plaintext
    input signal r; // Randomness

    output ProjectivePoint() gr; // g^r
    output ProjectivePoint() gv_pkr; // g^v * pk^r

    component scalarMul_gv = scalarMulProjective(n, A, B);
    scalarMul_gv.m <== v;
    scalarMul_gv.P <== g;
    ProjectivePoint() gv <== scalarMul_gv.out; // g^v

    component scalarMul_pkr = scalarMulProjective(n, A, B);
    scalarMul_pkr.m <== r;
    scalarMul_pkr.P <== pk;
    ProjectivePoint() pkr <== scalarMul_pkr.out; // pk^r

    component scalarMul_gr = scalarMulProjective(n, A, B);
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
*/
template expElGamalMontgomeryAffine(n, A, B) {
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

    component expElGamalMontgomeryProjective = expElGamalMontgomeryProjective(n, A, B);
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

component main = expElGamalMontgomeryProjective(32, 126932, 1);