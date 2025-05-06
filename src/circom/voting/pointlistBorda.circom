pragma circom 2.2.1;

include "../utilities/asserts.circom";
include "../../../libs/node_modules/circomlib/circuits/comparators.circom";
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
template assertPointlistBordaVoting(bitsVotes, nCand, nPoints, orderedPoints) {
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
