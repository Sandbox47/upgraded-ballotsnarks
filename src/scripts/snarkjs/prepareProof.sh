#!/bin/bash

# Roughly follows steps 8 and 15-22 of the approach outlined in https://github.com/iden3/snarkjs?tab=readme-ov-file. 
# Also take inspiration from https://docs.circom.io/getting-started/proving-circuits/#powers-of-tau.
# Uses the NIST random beacon 2.0 for random contributions. (https://csrc.nist.gov/projects/interoperable-randomness-beacons/beacon-20)

# Check for the required arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [--r] <circuit_file.r1cs> <ptau_file.ptau>"
    exit 1
fi

# Check for the optional --r flag
DO_RANDOMIZED_PHASE2=false
if [ "$1" == "--r" ]; then
  DO_RANDOMIZED_PHASE2=true
  shift # Remove the --r option from the arguments
fi

# Assign arguments to variables
R1CS_FILE=$1
POWERS_OF_TAU_FILE=$2

# 8. Verify provided powers of tau file
# snarkjs powersoftau verify "$POWERS_OF_TAU_FILE"
# echo "Verifed ptau file."

# 15. Setup Groth 16
snarkjs groth16 setup "$R1CS_FILE" "$POWERS_OF_TAU_FILE" circuit_0000.zkey
echo "Set up zkey."

# 16. Contribute to the phase 2 ceremony
randomness="Totally random bit string."
if [ "$DO_RANDOMIZED_PHASE2" = true ]; then
  # Endpoint for the latest randomness record
  URL="https://beacon.nist.gov/beacon/2.0/chain/1/pulse/last"

  # Fetch the randomness record using curl
  response=$(curl -s "$URL")

  # Parse the randomness value using jq
  randomness=$(echo "$response" | jq -r '.pulse.outputValue')
fi

# Extract base name of the R1CS file (without extension)
BASE_NAME=$(basename "$R1CS_FILE" .r1cs)
# Use the base name for the final zkey file
FINAL_ZKEY_FILE="${BASE_NAME}.zkey"

snarkjs zkey contribute circuit_0000.zkey "$FINAL_ZKEY_FILE" --name="First contribution" -v -e="$randomness"
echo "Contributed to zkey."

# 21. Verify the final zkey
snarkjs zkey verify "$R1CS_FILE" "$POWERS_OF_TAU_FILE" "$FINAL_ZKEY_FILE"
echo "Verified zkey."

# 22. Export the verification key
snarkjs zkey export verificationkey "$FINAL_ZKEY_FILE" "${BASE_NAME}_verification_key.json"
echo "Exported zkey."


# Next step would be to generate the proof