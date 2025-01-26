pragma circom 2.2.1;

include "../utilities/arithmetic.circom";
include "../../libs/node_modules/circomlib/circuits/comparators.circom";
include "../expElGamal/assertEEG.circom";

/**
* Counts the elements in the array that are greater than test.
* maxValue is the maximum value of any of the inputs (including test).
*/
template countGreater(n, maxValue) {
    input signal in[n];
    input signal test;

    output signal out;

    component isGreater[n];
    var counter = 0;
    var maxValueBits = numBits(maxValue);

    for(var i = 0; i < n; i++) {
        isGreater[i] = GreaterThan(maxValueBits);
        isGreater[i].in[0] <== in[i];
        isGreater[i].in[1] <== test;
        counter += isGreater[i].out;
    }

    out <== counter;
}

/**
* Counts the elements in the array that are equal to test.
*/
template countEqual(n) {
    input signal in[n];
    input signal test;

    output signal out;

    component isEqual[n];

    var counter = 0;

    for(var i = 0; i < n; i++) {
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== in[i];
        isEqual[i].in[1] <== test;
        counter += isEqual[i].out;
    }

    out <== counter;
}

/**
* Given: A ranking of length n and the points a and b to be given to each candidate ranked worse/ equal than the current one.
* The template then computes the according ballot. The maximum value any entry in the ranking can have is maxValue.
*/
template computeBordaTournamentStyleBallot(n, maxValue, a, b) {
    input signal ranking[n];

    output signal out[n]; // ballot

    component rankedWorse[n];
    component rankedTheSame[n];
    component getAccordingPoints[n];

    signal rankedWorsePoints[n];
    signal rankedTheSamePoints[n];

    for(var i = 0; i < n; i++) {
        rankedWorse[i] = countGreater(n, maxValue);
        rankedTheSame[i] = countEqual(n);

        rankedWorse[i].in <== ranking;
        rankedWorse[i].test <== ranking[i];

        rankedTheSame[i].in <== ranking;
        rankedTheSame[i].test <== ranking[i];

        rankedWorsePoints[i] <== a * rankedWorse[i].out;
        rankedTheSamePoints[i] <== b * (rankedTheSame[i].out - 1); // (... -1) to exclude the entry at position i

        out[i] <== rankedWorsePoints[i] + rankedTheSamePoints[i];
    }
}

/**
* Assert that the given ballot corresponds to the given ranking according to the borda tournament style election type.
* Parameters a, b, maxValue are defined the same as in computeBordaTournamentStyleBallot.
*/
template assertBordaTournamentStyleVoting(nVotes, maxValue, a, b) {
    input signal ranking[nVotes];
    input signal ballot[nVotes];

    component computeBallot = computeBordaTournamentStyleBallot(nVotes, maxValue, a, b);
    computeBallot.ranking <== ranking;

    ballot === computeBallot.out;
}

/**
* Combined circuit checking that the ballot is valid encrypting the ballot using expElGamal.
*/
template assertBordaTournamentStyle(bitsVotes, bitsRand, A, B, nVotes, maxValue, a, b) {
    // Public
    input ProjectivePoint() g; // Generator
    input ProjectivePoint() pk; // Public key, pk=g^b for some private b
    output ProjectivePoint() encBallot[2][nVotes]; //g^r and g^v*pk^r values from expElGamal

    // Private/Witness
    input signal ballot[nVotes];
    input signal ranking[nVotes];
    input signal r[nVotes]; // Randomness

    component enc = expElGamalVector(bitsVotes, bitsRand, A, B, nVotes);
    enc.v <== ballot;
    enc.g <== g;
    enc.pk <== pk;
    enc.r <== r;
    encBallot[0] <== enc.gr;
    encBallot[1] <== enc.gv_pkr;

    component assertVoting = assertBordaTournamentStyleVoting(nVotes, maxValue, a, b);
    assertVoting.ballot <== ballot;
    assertVoting.ranking <== ranking;
}

// component main = assertBordaTournamentStyleVoting(100, 100, 2, 1);
component main = assertBordaTournamentStyle(32, 255, 126932, 1, 100, 100, 2, 1);