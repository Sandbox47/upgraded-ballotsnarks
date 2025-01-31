#!/bin/bash

# Roughly follows step 23 of the approach outlined in https://github.com/iden3/snarkjs?tab=readme-ov-file. 
# Also take inspiration from https://docs.circom.io/getting-started/proving-circuits/#powers-of-tau.

# Check for the required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <circuit.zkey> <witness.wtns>"
    exit 1
fi

# Assign arguments to variables
ZKEY_FILE=$1
WITNESS_FILE=$2

# Create Proof
snarkjs groth16 prove "$ZKEY_FILE" "$WITNESS_FILE" proof.json public.json