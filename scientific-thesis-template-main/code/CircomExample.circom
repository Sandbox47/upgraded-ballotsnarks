pragma circom 2.2.1;

/**
* Circuit $\mathfrak{C}_{3\text{-}vot}$.
*/
template threeVot() {
    input signal S_1_in;
    input signal S_2_in;
    input signal S_3_in;

    output signal S_1_out;
    output signal S_2_out;
    output signal S_3_out;
    output signal S_4_out;

    S_1_out <== S_1_in*(1-S_1_in);
    S_2_out <== S_2_in*(1-S_2_in);
    S_3_out <== S_3_in*(1-S_3_in);

    S_4_out <== (S_1_in + S_2_in + S_3_in)*(1-S_1_in-S_2_in-S_3_in);
}

/**
* Circuit $\mathfrak{C}_{assert\text{-}3\text{-}vot}$.
*/
template assertThreeVot() {
    input signal S_1_in;
    input signal S_2_in;
    input signal S_3_in;

    0 === S_1_in*(1-S_1_in);
    0 === S_2_in*(1-S_2_in);
    0 === S_3_in*(1-S_3_in);

    0 === (S_1_in + S_2_in + S_3_in)*(1-S_1_in-S_2_in-S_3_in);
}

/**
* Circuit $\mathfrak{C}_{3\text{-}vot}$.
*/
/*
template threeVot() {
    input signal S_in[3];

    output signal S_out[4];

    var sum = 0;
    for(var i = 0; i < 3; i++) {
        S_out[i] <== S_in[i]*(1-S_in[i]);
        sum += S_in[i];
    }

    S_out[3] <== sum * (1-sum);
}
*/

/**
* Circuit $\mathfrak{C}_{is\text{-}Bit}$.
*/
template isBit() {
    input signal in;

    output signal out;

    out <== in*(1-in);
}

/**
* Circuit $\mathfrak{C}_{3\text{-}vot}$.
*/
/*
template threeVot() {
    input signal S_in[3];

    output signal S_out[4];

    component isBit[4];
    isBit[3] = isBit();

    var sum = 0;
    for(var i = 0; i < 3; i++) {
        isBit[i] = isBit();
        isBit[i].in <== S_in[i];
        S_out[i] <== isBit[i].out;
        sum += S_in[i];
    }

    isBit[3].in <== sum;
    S_out[3] <== isBit[3].out;
}
*/

/**
* Circuit $\mathfrak{C}_{3\text{-}vot}$.
*/
template vot(n) {
    input signal S_in[n];

    output signal S_out[n+1];

    component isBit[n+1];
    isBit[n] = isBit();

    var sum = 0;
    for(var i = 0; i < n; i++) {
        isBit[i] = isBit();
        isBit[i].in <== S_in[i];
        S_out[i] <== isBit[i].out;
        sum += S_in[i];
    }

    isBit[n].in <== sum;
    S_out[n] <== isBit[n].out;
}

/**
* Circuit $\mathfrak{C}_{division}$.
*/
template division() {
    input signal x;
    input signal y;

    output signal out;

    out <-- x/y;
    out * y === x;
    // log(out);
}

//component main = vot(3);
//component main {public [S_in]}= vot(3);
// component main = division();
component main = assertThreeVot();