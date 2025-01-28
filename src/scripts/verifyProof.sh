#!/bin/bash

# Roughly follows step 24 of the approach outlined in https://github.com/iden3/snarkjs?tab=readme-ov-file. 
# Also take inspiration from https://docs.circom.io/getting-started/proving-circuits/#powers-of-tau.

# Check for the required arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <verification_key.json> <public.json> <proof.json>"
    exit 1
fi

# Assign arguments to variables
VERIFICATION_KEY_FILE=$1
PUBLIC_FILE=$2
PROOF_FILE=$3

# Verify Proof
snarkjs groth16 verify "$VERIFICATION_KEY_FILE" "$PUBLIC_FILE" "$PROOF_FILE"