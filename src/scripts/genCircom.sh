#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <path_to_circomFile.circom> <path_to_inputFile.json>"
  exit 1
fi

# Assign arguments to variables
CIRCOM_FILE=$1
INPUT_FILE=$2

# Extract the base name of the CIRCOM file (without extension)
BASE_NAME=$(basename "$CIRCOM_FILE" .circom)

# Check if the input file is a Sage file or JSON
if [[ "$INPUT_FILE" == *.sage ]]; then
  # Generate the JSON input using the Sage file
  SAGE_OUTPUT="${INPUT_FILE%.sage}.json"
  
  # Run the Sage script and extract only the JSON part using a tool like jq or sed
  # sage "$INPUT_FILE"
  sage "$INPUT_FILE" | sed -n '/^{/,/^}$/p' > "$SAGE_OUTPUT"
  cat $SAGE_OUTPUT
  
  # Update INPUT_FILE to point to the generated JSON file
  INPUT_FILE="$SAGE_OUTPUT"
  # echo "Input file: $INPUT_FILE"
fi

# Run circom to generate r1cs, sym, and wasm files
circom "$CIRCOM_FILE" --r1cs --sym --wasm

# Navigate to the generated folder
cd "${BASE_NAME}_js" || { echo "Error: Could not change directory to ${BASE_NAME}_js"; exit 1; }

# Copy the input file to input.json in the target directory
cp "../$INPUT_FILE" input.json

# Generate the witness
node generate_witness.js "${BASE_NAME}.wasm" input.json witness.wtns

# Export the witness to JSON
snarkjs wtns export json witness.wtns

# Navigate back to the original directory
cd - || exit

echo "Automation complete."