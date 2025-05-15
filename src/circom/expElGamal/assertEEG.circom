pragma circom 2.2.1;

include "../curves/affinePoint.circom";
include "../curves/projectivePoint.circom";
include "expElGamal.circom";

// ========================================================================================================================
// MONTGOMERY

template assertEncMontgomeryProjective(bitsPlain, bitsRand, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v; // Signal
    input signal r; // Randomness

    // Test
    input ProjectivePoint() gr;
    input ProjectivePoint() gv_pkr;

    component expElGamal;

    expElGamal = expElGamalMontgomeryProjective(bitsRand, bitsPlain, A, B);
    expElGamal.g <== g;
    expElGamal.pk <== pk;
    expElGamal.v <== v;
    expElGamal.r <== r;

    gr === expElGamal.gr;
    gv_pkr === expElGamal.gv_pkr;
}

template assertEncVectorMontgomeryProjective(entries, bitsPlain, bitsRand, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[entries]; // Signal
    input signal r[entries]; // Randomness

    // Test
    input ProjectivePoint() gr[entries];
    input ProjectivePoint() gv_pkr[entries];

    component assertEnc[entries];

    for(var i = 0; i < entries; i++) {
        assertEnc[i] = assertEncMontgomeryProjective(bitsPlain, bitsRand, A, B);
        assertEnc[i].g <== g;
        assertEnc[i].pk <== pk;
        assertEnc[i].v <== v[i];
        assertEnc[i].r <== r[i];
        assertEnc[i].gr <== gr[i];
        assertEnc[i].gv_pkr <== gv_pkr[i];
    }
}

template assertEncMatrixMontgomeryProjective(rows, columns, bitsPlain, bitsRand, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[rows][columns]; // Signal
    input signal r[rows][columns]; // Randomness

    // Test
    input ProjectivePoint() gr[rows][columns];
    input ProjectivePoint() gv_pkr[rows][columns];

    component assertEnc[rows][columns];

    for(var i = 0; i < rows; i++) {
        for(var j = 0; j < columns; j++) {
            assertEnc[i][j] = assertEncMontgomeryProjective(bitsPlain, bitsRand, A, B);
            assertEnc[i][j].g <== g;
            assertEnc[i][j].pk <== pk;
            assertEnc[i][j].v <== v[i][j];
            assertEnc[i][j].r <== r[i][j];
            assertEnc[i][j].gr <== gr[i][j];
            assertEnc[i][j].gv_pkr <== gv_pkr[i][j];
        }
        
    }
}

// ========================================================================================================================
// TWISTED EDWARDS

/*
template assertEncTwistedEdwards(bitsPlain, bitsRand, a, d) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v; // Signal
    input signal r; // Randomness

    // Test
    input TwistedEdwardsPoint() gr;
    input TwistedEdwardsPoint() gv_pkr;

    component expElGamal;

    expElGamal = expElGamalTwistedEdwards(bitsRand, bitsPlain, a, d);
    expElGamal.powersOfg <== powersOfg;
    expElGamal.powersOfpk <== powersOfpk;
    expElGamal.v <== v;
    expElGamal.r <== r;
}

template assertEncVectorTwistedEdwards(entries, bitsPlain, bitsRand, a, d) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v[entries]; // Signal
    input signal r[entries]; // Randomness

    // Test
    input TwistedEdwardsPoint() gr[entries];
    input TwistedEdwardsPoint() gv_pkr[entries];

    component assertEnc[entries];

    for(var i = 0; i < entries; i++) {
        assertEnc[i] = assertEncTwistedEdwards(bitsPlain, bitsRand, a, d);
        assertEnc[i].powersOfg <== powersOfg;
        assertEnc[i].powersOfpk <== powersOfpk;
        assertEnc[i].v <== v[i];
        assertEnc[i].r <== r[i];
        assertEnc[i].gr <== gr[i];
        assertEnc[i].gv_pkr <== gv_pkr[i];
    }
}

template assertEncMatrixTwistedEdwards(rows, columns, bitsPlain, bitsRand, a, d) {
    input TwistedEdwardsPoint() powersOfg[bitsRand]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand]; // Powers of public key, pk=g^b for some private b
    input signal v[rows][columns]; // Signal
    input signal r[rows][columns]; // Randomness

    // Test
    input TwistedEdwardsPoint() gr[rows][columns];
    input TwistedEdwardsPoint() gv_pkr[rows][columns];

    component assertEnc[rows][columns];

    for(var i = 0; i < rows; i++) {
        for(var j = 0; j < columns; j++) {
            assertEnc[i][j] = assertEncTwistedEdwards(bitsPlain, bitsRand, a, d);
            assertEnc[i][j].powersOfg <== powersOfg;
            assertEnc[i][j].powersOfpk <== powersOfpk;
            assertEnc[i][j].v <== v[i][j];
            assertEnc[i][j].r <== r[i][j];
            assertEnc[i][j].gr <== gr[i][j];
            assertEnc[i][j].gv_pkr <== gv_pkr[i][j];
        }
        
    }
}
*/

// ========================================================================================================================
// TWISTED EDWARDS with arbitrary base

// template assertEncTwistedEdwardsArbitraryBase(bitsPlain, bitsRand, base, a, d) {
template assertEncTwistedEdwards(bitsPlain, bitsRand, base, a, d) { // TESTING ONLY!!!
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[bitsPlain][base]; // Plaintext
    input signal r[bitsRand][base]; // Randomness

    // Test
    input TwistedEdwardsPoint() gr;
    input TwistedEdwardsPoint() gv_pkr;

    component expElGamal;

    expElGamal = expElGamalTwistedEdwardsArbitraryBase(base, bitsRand, bitsPlain, a, d);
    expElGamal.powersOfg <== powersOfg;
    expElGamal.powersOfpk <== powersOfpk;
    expElGamal.v <== v;
    expElGamal.r <== r;
}

// template assertEncVectorTwistedEdwardsArbitraryBase(entries, bitsPlain, bitsRand, base, a, d) {
template assertEncVectorTwistedEdwards(entries, bitsPlain, bitsRand, base, a, d) { // TESTING ONLY!!!
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[entries][bitsPlain][base]; // Plaintext
    input signal r[entries][bitsRand][base]; // Randomness

    // Test
    input TwistedEdwardsPoint() gr[entries];
    input TwistedEdwardsPoint() gv_pkr[entries];

    component assertEnc[entries];

    for(var i = 0; i < entries; i++) {
        assertEnc[i] = assertEncTwistedEdwards(bitsPlain, bitsRand, base, a, d); // TESTING ONLY!!!
        assertEnc[i].powersOfg <== powersOfg;
        assertEnc[i].powersOfpk <== powersOfpk;
        assertEnc[i].v <== v[i];
        assertEnc[i].r <== r[i];
        assertEnc[i].gr <== gr[i];
        assertEnc[i].gv_pkr <== gv_pkr[i];
    }
}

// template assertEncMatrixTwistedEdwardsArbitraryBase(rows, columns, bitsPlain, bitsRand, base, a, d) {
template assertEncMatrixTwistedEdwards(rows, columns, bitsPlain, bitsRand, base, a, d) { // TESTING ONLY!!!
    input TwistedEdwardsPoint() powersOfg[bitsRand][base]; // Powers of generator
    input TwistedEdwardsPoint() powersOfpk[bitsRand][base]; // Powers of public key, pk=g^b for some private b
    input signal v[rows][columns][bitsPlain][base]; // Plaintext
    input signal r[rows][columns][bitsRand][base]; // Randomness

    // Test
    input TwistedEdwardsPoint() gr[rows][columns];
    input TwistedEdwardsPoint() gv_pkr[rows][columns];

    component assertEnc[rows][columns];

    for(var i = 0; i < rows; i++) {
        for(var j = 0; j < columns; j++) {
            assertEnc[i][j] = assertEncTwistedEdwards(bitsPlain, bitsRand, base, a, d); // TESTING ONLY!!!
            assertEnc[i][j].powersOfg <== powersOfg;
            assertEnc[i][j].powersOfpk <== powersOfpk;
            assertEnc[i][j].v <== v[i][j];
            assertEnc[i][j].r <== r[i][j];
            assertEnc[i][j].gr <== gr[i][j];
            assertEnc[i][j].gv_pkr <== gv_pkr[i][j];
        }
        
    }
}
