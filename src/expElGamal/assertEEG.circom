pragma circom 2.2.1;

include "../curves/affinePoint.circom";
include "../curves/projectivePoint.circom";
include "expElGamal.circom";

template parallel assertEnc(bitsPlain, bitsRand, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v; // Signal
    input signal r; // Randomness

    // Test
    input ProjectivePoint() gr;
    input ProjectivePoint() gv_pkr;

    component expElGamal;

    expElGamal = expElGamalMontgomeryProjective(bitsPlain, bitsRand, A, B);
    expElGamal.g <== g;
    expElGamal.pk <== pk;
    expElGamal.v <== v;
    expElGamal.r <== r;
    gr === expElGamal.gr;
    gv_pkr === expElGamal.gv_pkr;
}

template assertEncVector(entries, bitsPlain, bitsRand, A, B) {
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    input signal v[entries]; // Signal
    input signal r[entries]; // Randomness

    // Test
    input ProjectivePoint() gr[entries];
    input ProjectivePoint() gv_pkr[entries];

    component assertEnc[entries];

    for(var i = 0; i < entries; i++) {
        assertEnc[i] = assertEnc(bitsPlain, bitsRand, A, B);
        assertEnc[i].g <== g;
        assertEnc[i].pk <== pk;
        assertEnc[i].v <== v[i];
        assertEnc[i].r <== r[i];
        assertEnc[i].gr <== gr[i];
        assertEnc[i].gv_pkr <== gv_pkr[i];
    }
}

template assertEncMatrix(rows, columns, bitsPlain, bitsRand, A, B) {
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
            assertEnc[i][j] = assertEnc(bitsPlain, bitsRand, A, B);
            assertEnc[i][j].g <== g;
            assertEnc[i][j].pk <== pk;
            assertEnc[i][j].v <== v[i][j];
            assertEnc[i][j].r <== r[i][j];
            assertEnc[i][j].gr <== gr[i][j];
            assertEnc[i][j].gv_pkr <== gv_pkr[i][j];
        }
        
    }
}

// component main = assertEncVector(100, 32, 255, 126932, 1);