pragma circom 2.2.1;

bus ElementFieldQ(numberOfchunks) {
    signal chunks[numberOfChunks];
}

template modQ() {
    input ElementFieldQ(numberOfChunks) q;
    input signal element[numberOfChunks];

    


    output ElementFieldQ(numberOfChunks) mappedElement;
}

template isElementFieldQ() {
    // Declaration of signals.
    input ElementFieldQ(numberOfChunks) q;
    input ElementFieldQ(numberOfChunks) element;
    output ElementFieldQ(numberOfChunks) correct;

    // Constraints.

}

template hasOverflowAdd() {
    input signal a;
    input signal b;
    output signal overflow;

    signal sum <== a+b;
    if (sum < a || sum < b) {
        overflow <== 1;
    } else {
        overflow <== 0;
    }
}

template BaseQAdd(q) {

}

template BaseQSub() {

}

template BaseQMul() {

}

template BaseQDiv() {

}