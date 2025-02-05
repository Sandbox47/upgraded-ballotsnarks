#!/bin/bash

# ========================================================================================================================
# 1. Check argument validity
# Check for the required arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <electionType> <nBits> key1=value1 key2=value2 ..."
    exit 1
fi

# Assign input arguments to variables
electionType="$1"
nBits="$2"
shift 2 # Shift arguments so $@ now contains only key=value pairs

# Separate key-value pairs
positionalParams=()
namedParams=()

for arg in "$@"; do
    if [[ "$arg" == *=* ]]; then
        namedParams+=("$arg")  # Store key=value pairs for Sage
        positionalParams+=("${arg#*=}")  # Extract only the values for Circom
    else
        echo "Error: Arguments must be in key=value format."
        exit 1
    fi
done

# Convert arrays to properly formatted strings
positionalParamsString=$(IFS=', '; echo "${positionalParams[*]}")  # Comma-separated values
namedParamsString=$(IFS=', '; echo "${namedParams[*]}")  # Comma-separated key=value pairs

echo "Arguments valid."

# ========================================================================================================================
# 2. Create circom test file

# Convert the first letter of electionType to uppercase
capitalizedElectionType="$(echo "${electionType:0:1}" | tr '[:lower:]' '[:upper:]')${electionType:1}"

mkdir -p circomTestFiles # Ensure circom test file directory exists

# Define output file name (lowercase electionType)
testCircom="circomTestFiles/${electionType}.circom"

# Generate the test circom file
cat > "$testCircom" <<EOF
pragma circom 2.2.1;

include "../../voting/${electionType}.circom";

component main {public [g, pk, enc_gr, enc_gv_pkr]} = assert${capitalizedElectionType}(${nBits}, 255, 126932, 1, ${positionalParamsString});
EOF

echo "Circom test file '${testCircom}' created successfully."

# ========================================================================================================================
# 3. Create sage test file

mkdir -p sageTestFiles # Ensure sage test file directory exists

# Define output file name (lowercase electionType)
testSage="sageTestFiles/${electionType}.sage"

# Generate the test sage file
cat > "$testSage" <<EOF
from sageImport import sage_import

sage_import('../../sage/voting/ballot', fromlist=['Ballot'])
sage_import('../../sage/voting/${electionType}', fromlist=['${capitalizedElectionType}Ballot'])

Ballot.test(${capitalizedElectionType}Ballot, ${namedParamsString})
EOF

echo "Sage test file '${testCircom}' created successfully."

# ========================================================================================================================
# 4. Compile circuit, generate witness and extract constraint count

cd circomTestFiles
# Capture the output to extract the number of linear and non-linear contraints
compileOutput=$(genCircom.sh ${electionType}.circom ../sageTestFiles/${electionType}.sage 2>&1 | tee /dev/tty)
cd ..

# Extract non-linear constraints (ensures only exact match)
nonLinearConstraints=$(echo "$compileOutput" | grep -E "^non-linear constraints:" | awk '{print $3}')

# Extract linear constraints (ensures it doesn’t match non-linear)
linearConstraints=$(echo "$compileOutput" | grep -E "^linear constraints:" | awk '{print $3}')

# Check if the witness file was created successfully
if [ ! -f "circomTestFiles/${electionType}_js/witness.wtns" ]; then
    echo "Error: witness.wtns was not generated."
    exit 1
fi

echo "Witness generated successfully."

# ========================================================================================================================
# 5. Prepare proof

# 5.1. Find smallest ptau file possible:

# Total constraints:
constraints=$(($nonLinearConstraints + $linearConstraints));
echo "${constraints} constraints in total."

# Define the range of ptau files available
min_n=8
max_n=22
ptauFile=""

# Iterate through available ptau files to find the smallest valid one
for ((n=min_n; n<=max_n; n++)); do
    if (( (1 << n) >= constraints )); then
        ptauFile="powersOfTau_${n}.ptau"
        break
    fi
done

# Check if a suitable ptau file was found
if [[ -z "$ptauFile" ]]; then
    echo "Error: No suitable ptau file found for $constraints constraints." >&2
    exit 1
fi

echo "Using ptau file: $ptauFile"

# 5.2. Preparing proof with existing shell script
mkdir -p snarkjsTestFiles # Ensure snarkjs test file directory exists
cd snarkjsTestFiles
start_time=$(date +%s%3N)
prepareProof.sh ../circomTestFiles/${electionType}.r1cs ../../scripts/ptau/${ptauFile}
end_time=$(date +%s%3N)
t_prep=$((end_time - start_time))

if [ ! -f "${electionType}.zkey" ]; then
    echo "Error: ${electionType}.zkey was not generated."
    exit 1
fi

echo "Zkey file generated successfully in ${t_prep} milliseconds."
cd ..

# ========================================================================================================================
# 6. Prove

cd snarkjsTestFiles
start_time=$(date +%s%3N)
createProof.sh ${electionType}.zkey ../circomTestFiles/${electionType}_js/witness.wtns
end_time=$(date +%s%3N)
t_prove=$((end_time - start_time))

echo "Proof created successfully in ${t_prove} milliseconds."
cd ..

# ========================================================================================================================
# 7. Verify

cd snarkjsTestFiles
start_time=$(date +%s%3N)
verifyProof.sh ${electionType}_verification_key.json public.json proof.json
end_time=$(date +%s%3N)
t_ver=$((end_time - start_time))

echo "Proof verified successfully in ${t_ver} milliseconds."
cd ..

# ========================================================================================================================
# 8. Export results
indicator="${nBits},${positionalParamsString}"  # Unique indicator for each run

# Extract argument names from key=value pairs
argNames=("Number of Bits")  # Start with "Number of Bits"
for arg in "${namedParams[@]}"; do
    argNames+=("${arg%%=*}")  # Extract key (before '=')
done

# 8.1: Preparation, proving and verification times

# Create header row dynamically
headerTimes="$(IFS=';'; echo "${argNames[*]};t_prep;t_prove;t_ver")"

csvFileTimes="times/${electionType}.csv"
mkdir -p times  # Ensure results directory exists

lineTimes="${indicator};${t_prep};${t_prove};${t_ver}"

# If the CSV file does not exist, create it with a header
if [ ! -f "$csvFileTimes" ]; then
    echo "$headerTimes" > "$csvFileTimes"
fi

# Replace the lineTimes if the indicator already exists, otherwise append it
grep -v "^${indicator};" "$csvFileTimes" > temp.csv || true
echo "$lineTimes" >> temp.csv
mv temp.csv "$csvFileTimes"

echo "Exported preparation, proving and verification times."

# 8.2: Constraint count

# Create header row dynamically
headerConstraints="$(IFS=';'; echo "${argNames[*]};non-linear constraints;linear contraints;total constraints")"

csvFileConstraints="constraints/${electionType}.csv"
mkdir -p constraints  # Ensure results directory exists

lineConstraints="${indicator};${nonLinearConstraints};${linearConstraints};${constraints}"

# If the CSV file does not exist, create it with a header
if [ ! -f "$csvFileConstraints" ]; then
    echo "$headerConstraints" > "$csvFileConstraints"
fi

# Replace the lineConstraints if the indicator already exists, otherwise append it
grep -v "^${indicator};" "$csvFileConstraints" > temp.csv || true
echo "$lineConstraints" >> temp.csv
mv temp.csv "$csvFileConstraints"

echo "Exported constraint count (non-lin, lin, total)=(${nonLinearConstraints}, ${linearConstraints}, ${constraints})."