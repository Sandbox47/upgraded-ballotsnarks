#!/bin/bash

# Measure the start time
start_time=$(date +%s)

# Check if the required arguments are provided
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [--c] <path_to_someFile.circom> <path_to_inputFile.json_or_sageFile.sage>"
  exit 1
fi

# Check for the optional --c flag
USE_CPP_WITNESS=false
if [ "$1" = "--c" ]; then
  USE_CPP_WITNESS=true
  shift # Remove the --c option from the arguments
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
  # sage "$INPUT_FILE" | tee /dev/tty | sed -n '/^{/,/^}$/p' > "$SAGE_OUTPUT"
  # cat "$SAGE_OUTPUT"
  
  # Update INPUT_FILE to point to the generated JSON file
  INPUT_FILE="$SAGE_OUTPUT"
  # echo "Input file: $INPUT_FILE"
fi

# echo "Current location: ${PWD}"
# echo "Circom test file: ${CIRCOM_FILE}"

# Run circom to generate r1cs, sym, and wasm files (or C++ if --c is used)
if [ "$USE_CPP_WITNESS" = true ]; then
  circom "$CIRCOM_FILE" --r1cs --sym --c --O2

  # Navigate to the generated folder
  cd "${BASE_NAME}_cpp" || { echo "Error: Could not change directory to ${BASE_NAME}_cpp"; exit 1; }

  # Copy the input file to input.json in the target directory
  cp "../$INPUT_FILE" input.json

  # Generate the witness
  make
  ./$BASE_NAME input.json witness.wtns
else
  circom "$CIRCOM_FILE" --r1cs --sym --wasm --O2
  
  # Navigate to the generated folder
  cd "${BASE_NAME}_js" || { echo "Error: Could not change directory to ${BASE_NAME}_js"; exit 1; }

  # Copy the input file to input.json in the target directory
  cp "../$INPUT_FILE" input.json

  # Generate the witness
  node generate_witness.js "${BASE_NAME}.wasm" input.json witness.wtns
fi

# Export the witness to JSON
snarkjs wtns export json witness.wtns

# Navigate back to the original directory
cd - || exit

# Measure the end time
end_time=$(date +%s)
execution_time=$((end_time - start_time))

echo "Automation complete in $execution_time seconds."