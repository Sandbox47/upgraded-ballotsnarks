pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../expElGamal/assertEEG.circom";

/**
* Computes, how often choice occurs in a list of values valuesList of length n.
*/
template getOccurences(n) {
    input signal choice;
    input signal valuesList[n];

    output signal out;

    var counter = 0;
    component comparators[n];

    for(var i = 0; i < n; i++) {
        comparators[i] = IsEqual();
        comparators[i].in[0] <== choice;
        comparators[i].in[1] <== valuesList[i];

        counter += comparators[i].out;
    }

    out <== counter;
}

/**
* Asserts a Borda ballot.
* If nCand > nPoints, we assume, that the pointlist is padded with (Ncand - nPoints) zeros.
* orderedPoints is the list of points (descending order) and has length m. TODO: Does the ordering matter?
*/
template assertPointlistBordaVoting(nCand, nPoints, orderedPoints) {
    input signal ballot[nCand];

    signal expectedZeros <== nCand - nPoints;
    component getOccurencesZero = getOccurences(nCand);
    getOccurencesZero.choice <== 0;
    getOccurencesZero.valuesList <== ballot;
    signal numZeros <== getOccurencesZero.out;
    numZeros === expectedZeros;

    component getOccurences[nPoints];

    for(var i = 0; i < nPoints; i++) {
        getOccurences[i] = getOccurences(nCand);
        getOccurences[i].choice <== orderedPoints[i];
        getOccurences[i].valuesList <== ballot;

        getOccurences[i].out === 1;
    }
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
/*
template assertPointlistBorda(bitsVotes, bitsRand, A, B, nCand, nPoints, orderedPoints) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nCand]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nCand];
    input signal r[nCand]; // Randomness

    component enc = expElGamalVector(bitsVotes, bitsRand, A, B, nCand);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertPointlistBordaVoting(nCand, nPoints, orderedPoints);
    assertVoting.ballot <== ballot;
}
*/

/**
* Combined circuit checking that the ballot is valid and that the encrypted ballot is the encryption of the provided ballot.
*/
template assertPointlistBorda(bitsVotes, bitsRand, A, B, nCand, nPoints, orderedPoints) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input ProjectivePoint() enc_gr[nCand];
    input ProjectivePoint() enc_gv_pkr[nCand];

    // Private/Witness
    input signal ballot[nCand];
    input signal r[nCand]; // Randomness

    component assertEnc = assertEncVector(nCand, bitsVotes, bitsRand, A, B);
    assertEnc.v <== ballot;
    assertEnc.g <== g;
    assertEnc.pk <== pk;
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;

    component assertVoting = assertPointlistBordaVoting(nCand, nPoints, orderedPoints);
    assertVoting.ballot <== ballot;
}

// component main = getOccurences(100);
// component main = assertPointlistBordaVoting(100, 5, [12, 10, 8, 5, 1]);
// component main = assertPointlistBorda(32, 255, 126932, 1, 10, 5, [12, 10, 8, 5, 1]);