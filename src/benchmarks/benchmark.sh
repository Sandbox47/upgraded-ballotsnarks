#!/bin/bash

# Give Javascript heap more memory
export NODE_OPTIONS="--max-old-space-size=16384"

# ========================================================================================================================
# 1. Check argument validity
# Check for the required arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <mode> <electionType> <nBits> key1=value1 key2=value2 ..."
    echo "Allowed values for <mode>: voting, encryption, combined"
    exit 1
fi

# Assign input arguments to variables
mode="$1"
electionType="$2"
nBits="$3"
shift 3 # Shift arguments so $@ now contains only key=value pairs

# Validate mode
if [[ "$mode" != "voting" && "$mode" != "encryption" && "$mode" != "combined" ]]; then
    echo "Error: Invalid mode '$mode'. Allowed values: voting, encryption, combined."
    exit 1
fi

# Create election type test folder (if it does not exist already)
mkdir -p "${electionType}"
cd "${electionType}"

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

# Create File prefix
filePrefix="${electionType}_nBits=${nBits}_${namedParamsString}"

# Remove pointlist if election type is Pointlist-Borda
if [ "$electionType" = "pointlistBorda" ]; then
    filePrefix="${filePrefix%",orderedPoints"*}"
fi
echo "File prefix: ${filePrefix}"
echo "Arguments valid."

# ========================================================================================================================
# 2. Create circom test file

# Convert the first letter of electionType to uppercase
capitalizedElectionType="$(echo "${electionType:0:1}" | tr '[:lower:]' '[:upper:]')${electionType:1}"

mkdir -p circomTestFiles # Ensure circom test file directory exists

# Define output file name (lowercase electionType)
testCircom="circomTestFiles/${filePrefix}.circom"

# Determine the correct component name
if [ "$mode" == "combined" ]; then
    circomComponent="assert${capitalizedElectionType}"
elif [ "$mode" == "encryption" ]; then
    circomComponent="assert${capitalizedElectionType}EncryptionBenchmark"
elif [ "$mode" == "voting" ]; then
    circomComponent="assert${capitalizedElectionType}VotingBenchmark"
fi

# Generate the test circom file
cat > "$testCircom" <<EOF
pragma circom 2.2.1;

include "../../../voting/${electionType}.circom";

component main {public [g, pk, enc_gr, enc_gv_pkr]} = ${circomComponent}(${nBits}, 255, 126932, 1, ${positionalParamsString});
EOF

echo "Circom test file '${testCircom}' created successfully with component ${circomComponent}."

# ========================================================================================================================
# 3. Create sage test file

mkdir -p sageTestFiles # Ensure sage test file directory exists

# Define output file name (lowercase electionType)
testSage="sageTestFiles/${filePrefix}.sage"

# Generate the test sage file
cat > "$testSage" <<EOF
from sageImport import sage_import

sage_import('../../../sage/voting/ballot', fromlist=['Ballot'])
sage_import('../../../sage/voting/${electionType}', fromlist=['${capitalizedElectionType}Ballot'])

Ballot.test(${capitalizedElectionType}Ballot, ${namedParamsString})
EOF

echo "Sage test file '${testCircom}' created successfully."

# ========================================================================================================================
# 4. Compile circuit, generate witness and extract constraint count

cd circomTestFiles
# Capture the output to extract the number of linear and non-linear contraints
compileOutput=$(genCircom.sh ${filePrefix}.circom ../sageTestFiles/${filePrefix}.sage 2>&1 | tee /dev/tty)
cd ..

# Extract non-linear constraints (ensures only exact match)
nonLinearConstraints=$(echo "$compileOutput" | grep -E "^non-linear constraints:" | awk '{print $3}')

# Extract linear constraints (ensures it doesn’t match non-linear)
linearConstraints=$(echo "$compileOutput" | grep -E "^linear constraints:" | awk '{print $3}')

# Check if the witness file was created successfully
if [ ! -f "circomTestFiles/${filePrefix}_js/witness.wtns" ]; then
    echo "Error: witness.wtns was not generated."
    exit 1
fi

echo "Witness generated successfully."

# ========================================================================================================================
# 5. Prepare proof

# 5.1. Find smallest ptau file possible for this test circuit:

# Total constraints:
constraints=$(($nonLinearConstraints + $linearConstraints));
echo "${constraints} constraints in total."

# Define the range of ptau files available
# min_n=8
min_n=12 # For some of the smaller ptau files there is a weird bug where snarkjs claims that the file is too small even though it should be big enpugh for more than twice the constraints of the tested circuit. That's why we start with n=12.
max_n=25 # TODO: Change back to 22 later
ptauFile=""

# Iterate through available ptau files to find the smallest valid one
for ((n=min_n; n<=max_n; n++)); do
    if (( (1 << n) >= 2*constraints )); then # For some reason I need this factor 2 here (otherwise snarkjs sometimes complains that the powers of tau file is too small)
        ptauFile="powersOfTau_${n}.ptau"
        break
    fi
done

# Check if a suitable ptau file was found
if [[ -z "$ptauFile" ]]; then
    echo "Error: No suitable ptau file found for $constraints constraints." >&2
    exit 1
fi

ptauFile="powersOfTau_25.ptau" # There are some really weird bugs in the snarkjs constraint number computation so I'm just going to use the largest ptau file.
# TODO: Change back to 22 later

echo "Using ptau file: $ptauFile"

# 5.2. Preparing proof with existing shell script
mkdir -p snarkjsTestFiles # Ensure snarkjs test file directory exists
cd snarkjsTestFiles
start_time=$(date +%s%3N)
prepareProof.sh ../circomTestFiles/${filePrefix}.r1cs ../../../scripts/ptau/${ptauFile}
end_time=$(date +%s%3N)
t_prep=$((end_time - start_time))

if [ ! -f "${filePrefix}.zkey" ]; then
    echo "Error: ${filePrefix}.zkey was not generated."
    exit 1
fi

crsSize=$(stat -c%s "${filePrefix}.zkey")
crsSize=$(echo "scale=6; $crsSize / 1024 / 1024" | bc)

echo "Zkey file (${crsSize} mb) generated successfully in ${t_prep} milliseconds."
cd ..

# ========================================================================================================================
# 6. Prove

cd snarkjsTestFiles
start_time=$(date +%s%3N)
# Create Proof
snarkjs groth16 prove ${filePrefix}.zkey ../circomTestFiles/${filePrefix}_js/witness.wtns proof.json public.json # Use prove command directly for more accurate proving times
# createProof.sh ${filePrefix}.zkey ../circomTestFiles/${filePrefix}_js/witness.wtns
end_time=$(date +%s%3N)
t_prove=$((end_time - start_time))

echo "Proof created successfully in ${t_prove} milliseconds."
cd ..

# ========================================================================================================================
# 7. Verify

cd snarkjsTestFiles
start_time=$(date +%s%3N)
verifyProof.sh ${filePrefix}_verification_key.json public.json proof.json
end_time=$(date +%s%3N)
t_ver=$((end_time - start_time))

echo "Proof verified successfully in ${t_ver} milliseconds."
cd ..

# ========================================================================================================================
# 8. Export results

# Create results folder if it does not exist already
cd ..
mkdir -p "results"

# Create subfolder if it does not exist
mkdir -p "results/${mode}"

# Define the results CSV file path
csvFile="results/${mode}/${electionType}.csv"

indicator="${nBits},${positionalParamsString}"  # Unique indicator for each run

# Extract argument names from key=value pairs
argNames=("Number of Bits")  # Start with "Number of Bits"
for arg in "${namedParams[@]}"; do
    argNames+=("${arg%%=*}")  # Extract key (before '=')
done

# Create header row dynamically
header="$(IFS=';'; echo "${argNames[*]};non-linear constraints;linear contraints;total constraints; CRS size [MB]; t_prep [ms];t_prove [ms];t_ver [ms]")"

line="${indicator};${nonLinearConstraints};${linearConstraints};${constraints};${crsSize};${t_prep};${t_prove};${t_ver}"

# If the CSV file does not exist, create it with a header
if [ ! -f "$csvFile" ]; then
    echo "$header" > "$csvFile"
fi

# Replace the line if the indicator already exists, otherwise append it
grep -v "^${indicator};" "$csvFile" > temp.csv || true
echo "$line" >> temp.csv
mv temp.csv "$csvFile"

echo "Results saved in 'results/${mode}/${electionType}.csv'."
echo "Exported constraint count (non-lin, lin, total)=(${nonLinearConstraints}, ${linearConstraints}, ${constraints})."
echo "Exported CRS size (${crsSize}MB)."
echo "Exported times (preparation, proving, verification)=(${t_prep}ms, ${t_prove}ms, ${t_ver}ms)."

# ========================================================================================================================
# 9. Cleanup

echo "Cleaning up unnecessary files..."

cd "${electionType}"
rm -rf circomTestFiles
rm -rf sageTestFiles
rm -rf snarkjsTestFiles
cd ..

echo "Cleanup complete."