import os
import sys
import subprocess
import time
from pathlib import Path
import json
from JSON import JSONUtils
import re
import math
import argparse

# Increase Javascript heap memory
os.environ["NODE_OPTIONS"] = "--max-old-space-size=16384"

# Ptau file
def get_largest_ptau_file(folder_path):
    pattern = re.compile(r"^powersOfTau28_hez_final_(\d+)\.ptau$")
    max_n = -1
    max_file = None

    for file_name in os.listdir(folder_path):
        match = pattern.match(file_name)
        if match:
            n = int(match.group(1))
            if n > max_n:
                max_n = n
                max_file = file_name

    return max_file

PTAU_FILE = get_largest_ptau_file("../scripts/ptau/")
print(f"Using ptau file: {PTAU_FILE}")

BITS_RAND=255
BITS_PLAIN=32
TE_ENC_BASE = 5
DIGITS_PLAIN = math.ceil(BITS_PLAIN/math.log(TE_ENC_BASE, 2))
DIGITS_RAND = math.ceil(BITS_RAND/math.log(TE_ENC_BASE, 2))

# Montgomery curve parameters
Mon_A=126932
Mon_B=1
MONTGOMERY_CURVE_PARAMS = str(Mon_A) + ", " + str(Mon_B)
MONTGOMERY_CURVE_PARAMS_NAMES = "Mon_A, Mon_B"
# Twisted Edwards curve parameters
TE_a=126934
TE_d=126930
TWISTED_EDWARDS_CURVE_PARAMS = str(TE_a) + ", " + str(TE_d)
TWISTED_EDWARDS_CURVE_PARAMS_NAMES = "TE_a, TE_d"

# Utilities

def execute_shell_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(f"Error executing command: {command}")
        sys.exit(1)

    return result.stdout

def capitalize_first_letter(string):
    return string[0].upper() + string[1:]

# ========================================================================================================================
# 1. Check argument validity

# Check for the required arguments
def validate_args(args):
    if len(args) < 4:
        print("Usage: benchmark.py [<input>] <snark> <mode> <ellipticCurve> <electionType> <nBits> key1=value1 key2=value2 ...")
        print("<input> is an optional argument")
        print("Allowed values for <snark>: groth16, plonk, fflonk")
        print("Allowed values for <mode>: voting, encryption, combined")
        sys.exit(1)

# Assign input arguments to variables
def parse_arguments():
    input_file = None
    param_start = 1
    if sys.argv[1].endswith(".json"):
        input_file = sys.argv[1]
        param_start += 1

    snark, mode, elliptic_curve, election_type, n_bits, *kv_pairs = sys.argv[param_start:]
    named_params = {}
    for arg in kv_pairs:
        if "=" in arg:
            key, value = arg.split("=", 1)
            named_params[key] = value
        else:
            print(f"Error: Invalid argument '{arg}', expected key=value format.")
            sys.exit(1)
    n_digits =  str(math.ceil(int(n_bits)/math.log(TE_ENC_BASE, 2))) if elliptic_curve == "twistedEdwards" else n_bits
    return input_file, snark, mode, elliptic_curve, election_type, n_bits, n_digits, named_params

def prepare_directories(snark, elliptic_curve, election_type):
    base_path = Path(snark) / elliptic_curve / election_type
    base_path.mkdir(parents=True, exist_ok=True)
    return base_path

# ========================================================================================================================
# 2. Create circom test file

def create_circom_file(base_path, mode, election_type, elliptic_curve, n_bits, n_digits, named_params):
    circom_config = None
    with open('circomConfig.json') as circom_config_file:
        circom_config = json.load(circom_config_file)

    curves = circom_config["ellipticCurves"]
    election_types = circom_config["electionTypes"]
    election_type_config = election_types[election_type]
    curve_config = curves[elliptic_curve]

    curve_point_name = curve_config["curve_point_name"]
    g_name = curve_config["g_name"]
    pk_name = curve_config["pk_name"]
    g_dim = curve_config["g_dim"]
    pk_dim = curve_config["pk_dim"]
    curve_params_name = curve_config["curve_params_name"]
    curve_params_str = curve_config["curve_params_str"]
    ballot_entry_dim_for_enc = curve_config["ballot_entry_dim_for_enc"]
    r_entry_dim = curve_config["r_entry_dim"]

    election_type_dim = election_type_config["dim"]
    election_type_dim_array_str = "[" + ']['.join(election_type_dim) + "]"
    election_type_dim_str = ','.join(election_type_dim)
    election_type_ballot_format = election_type_config["ballot_format"]
    election_type_has_ranking = election_type_config["has_ranking"]
    election_type_ranking_dim = None
    if election_type_has_ranking:
        election_type_ranking_dim = election_type_config["ranking_dim"]
    election_type_named_params_names = ','.join(named_params.keys())
    election_type_named_params_values = ','.join(named_params.values())

    rand_digits = DIGITS_RAND if elliptic_curve == "twistedEdwards" else BITS_RAND

    file_header = f"""
pragma circom 2.2.1;
include \"../../../../../circom/voting/{election_type}.circom\";
    """

    template_method_signature = f"""
template assert{capitalize_first_letter(election_type)}(n_bits, n_digits, rand_digits, {curve_params_name}, {election_type_named_params_names})
    """

    template_input_output = f"""
    // Public
    input {curve_point_name}() {g_name}{g_dim}; // Generator
    input {curve_point_name}() {pk_name}{pk_dim}; // Public key, pk=g^b for some private b

    //g^r and g^v*pk^r values from expElGamal
    input {curve_point_name}() enc_gr{election_type_dim_array_str};
    input {curve_point_name}() enc_gv_pkr{election_type_dim_array_str};

    // Private/Witness
    input signal ballot{election_type_dim_array_str};
    input signal ballot_for_enc{election_type_dim_array_str}{ballot_entry_dim_for_enc};
    input signal r{election_type_dim_array_str}{r_entry_dim}; // Randomness
    """

    if election_type_has_ranking:
        template_input_output += f"""
    input signal ranking{election_type_ranking_dim};
        """

    template_assert_encryption = f"""
    component assertEnc = assertEnc{election_type_ballot_format}{capitalize_first_letter(elliptic_curve)}({election_type_dim_str}, n_digits, rand_digits, {curve_params_name});
    assertEnc.v <== ballot_for_enc;
    assertEnc.{g_name} <== {g_name};
    assertEnc.{pk_name} <== {pk_name};
    assertEnc.r <== r;
    assertEnc.gr <== enc_gr;
    assertEnc.gv_pkr <== enc_gv_pkr;    
    """

    template_assert_voting = f"""
    component assertVoting = assert{capitalize_first_letter(election_type)}Voting(n_bits, {election_type_named_params_names});
    assertVoting.ballot <== ballot;
    """

    if election_type_has_ranking:
        template_assert_voting += f"""
    assertVoting.ranking <== ranking;
    """

    file_main_component = f"""
component main {{public [{g_name}, {pk_name}, enc_gr, enc_gv_pkr]}} = assert{capitalize_first_letter(election_type)}({n_bits}, {n_digits}, {rand_digits}, {curve_params_str}, {election_type_named_params_values});
    """

    circom_file = file_header + "\n" + template_method_signature + "{\n" + template_input_output
    if mode == "encryption" or mode == "combined":
        circom_file += "\n" + template_assert_encryption
    if mode == "voting" or mode == "combined":
        circom_file += "\n" + template_assert_voting

    circom_file += "}\n" + file_main_component

    circom_file_name_prefix = f"{election_type}_nBits={n_bits}_" + ",".join(f"{k}={v}" for k, v in named_params.items())
    circom_file_name_prefix = re.sub(r',?\s*orderedPoints=\[[^\]]*\]$', '', circom_file_name_prefix) # Remove Pointlist from file name to avoid file names getting to large

    circom_path = base_path / "circomTestFiles"
    circom_path.mkdir(exist_ok=True)
    circom_file_name = circom_path / f"{circom_file_name_prefix}.circom"

    with circom_file_name.open("w") as f:
        f.write(circom_file)
    print(f"Circom test file '{circom_file_name}' created successfully.")

    return circom_file_name_prefix

# ========================================================================================================================
# 3. Create sage test file

def create_sage_file(base_path, file_prefix, elliptic_curve, election_type, n_bits, named_params):
    named_params_string = ", ".join(f"{k}={v}" for k, v in named_params.items())

    sage_path = base_path / "sageTestFiles"
    sage_path.mkdir(exist_ok=True)
    sage_file = sage_path / f"{file_prefix}.sage"
    with sage_file.open("w") as f:
        f.write(f"""
from sageImport import sage_import

sage_import('../../../../../sage/voting/ballot', fromlist=['Ballot'])
sage_import('../../../../../sage/voting/{election_type}', fromlist=['{capitalize_first_letter(election_type)}Ballot'])
sage_import('../../../../../sage/ellipticCurves/curve', fromlist=['CurvePoint'])
sage_import('../../../../../sage/ellipticCurves/Montgomery', fromlist=['MontgomeryAffinePoint', 'MontgomeryProjectivePoint'])
sage_import('../../../../../sage/ellipticCurves/TwistedEdwards', fromlist=['TwistedEdwardsPoint'])

Ballot.test({capitalize_first_letter(election_type)}Ballot, {capitalize_first_letter(elliptic_curve)}Point, {n_bits}, {named_params_string})
        """)
    print(f"Sage test file '{sage_file}' created successfully.")

# ========================================================================================================================
# 4. Compile circuit, generate witness and extract constraint count

def compile_circuit(base_path, file_prefix, snark, input_file):
    optimization = 2 if snark == "groth16" else 1
    circom_test_path = base_path / "circomTestFiles"
    compile_output = None
    if input_file == None:
        compile_output = execute_shell_command(f"cd {circom_test_path} && genCircom.sh {file_prefix}.circom ../sageTestFiles/{file_prefix}.sage {optimization}")
    else:
        compile_output = execute_shell_command(f"cd {circom_test_path} && genCircom.sh {file_prefix}.circom ../../../../{input_file} {optimization}")

    non_linear_constraints = next((line.split()[2] for line in compile_output.splitlines() if line.startswith("non-linear constraints:")), "0")
    linear_constraints = next((line.split()[2] for line in compile_output.splitlines() if line.startswith("linear constraints:")), "0")
    
    witness_file = circom_test_path / f"{file_prefix}_js/witness.wtns"
    if not witness_file.exists():
        print("Error: witness.wtns was not generated.")
        sys.exit(1)
    
    print("Witness generated successfully.")
    return int(non_linear_constraints), int(linear_constraints)

# ========================================================================================================================
# 5. Prepare proof

def prepare_proof(snark, base_path, file_prefix):
    snarkjs_path = base_path / "snarkjsTestFiles"
    snarkjs_path.mkdir(exist_ok=True)

    start_time = time.time()
    if (snark == "groth16"):
        execute_shell_command(f"cd {snarkjs_path} && prepareProof.sh ../circomTestFiles/{file_prefix}.r1cs ../../../../../scripts/ptau/{PTAU_FILE}")
    elif (snark == "plonk" or snark == "fflonk"):
        execute_shell_command(f"cd {snarkjs_path} && snarkjs {snark} setup ../circomTestFiles/{file_prefix}.r1cs ../../../../../scripts/ptau/{PTAU_FILE} {file_prefix}.zkey")

    execute_shell_command(f"cd {snarkjs_path} && snarkjs zkey export verificationkey {file_prefix}.zkey {file_prefix}_verification_key.json")
    end_time = time.time()
    
    t_prep = int((end_time - start_time) * 1000)
    zkey_file = snarkjs_path / f"{file_prefix}.zkey"
    if not zkey_file.exists():
        print(f"Error: {file_prefix}.zkey was not generated.")
        sys.exit(1)
    crs_size = zkey_file.stat().st_size / (1024 * 1024)
    print(f"Zkey file ({crs_size:.6f} MB) generated successfully in {t_prep} milliseconds.")
    return t_prep, crs_size

# ========================================================================================================================
# 6. Prove

def prove(snark, base_path, file_prefix):
    snarkjs_path = base_path / "snarkjsTestFiles"
    start_time = time.time()
    execute_shell_command(f"cd {snarkjs_path} && snarkjs {snark} prove {file_prefix}.zkey ../circomTestFiles/{file_prefix}_js/witness.wtns proof.json public.json")
    end_time = time.time()
    t_prove = int((end_time - start_time) * 1000)
    print(f"Proof generated in {t_prove} milliseconds.")
    return t_prove

# ========================================================================================================================
# 7. Verify

def verify_proof(snark, base_path, file_prefix):
    snarkjs_path = base_path / "snarkjsTestFiles"
    start_time = time.time()
    execute_shell_command(f"cd {snarkjs_path} && snarkjs {snark} verify {file_prefix}_verification_key.json public.json proof.json")
    end_time = time.time()
    t_ver = int((end_time - start_time) * 1000)
    print(f"Verification completed in {t_ver} milliseconds.")
    return t_ver

# ========================================================================================================================
# 8. Export results

def export_results(snark, elliptic_curve, mode, election_type, n_bits, named_params, non_linear_constraints, linear_constraints, crs_size, t_prep, t_prove, t_ver):
    results_path = Path(snark) / elliptic_curve / "results" / mode
    results_path.mkdir(parents=True, exist_ok=True)
    csv_file = results_path / f"{election_type}.csv"
    
    indicator = f"{n_bits};{';'.join(named_params.values())}"
    header = "Number of Bits;" + ";".join(named_params.keys()) + ";non-linear constraints;linear constraints;total constraints;CRS size [MB];t_prep [ms];t_prove [ms];t_ver [ms]"
    line = f"{indicator};{non_linear_constraints};{linear_constraints};{non_linear_constraints + linear_constraints};{crs_size};{t_prep};{t_prove};{t_ver}"
    
    if not csv_file.exists():
        csv_file.write_text(header + "\n")
    
    existing_lines = csv_file.read_text().splitlines()
    existing_lines = [l for l in existing_lines if not l.startswith(f"{indicator};")]
    existing_lines.append(line)
    csv_file.write_text("\n".join(existing_lines) + "\n")
    print(f"Results saved in '{csv_file}'.")

# ========================================================================================================================
# 9. Cleanup

def cleanup(base_path):
    for folder in ["circomTestFiles", "sageTestFiles", "snarkjsTestFiles"]:
        subprocess.run(f"rm -rf {base_path / folder}", shell=True)
    print("Cleanup complete.")

# ========================================================================================================================
# MAIN

def main():
    validate_args(sys.argv[1:])
    input_file, snark, mode, elliptic_curve, election_type, n_bits, n_digits, named_params = parse_arguments()
    base_path = prepare_directories(snark, elliptic_curve, election_type)
    file_prefix = create_circom_file(base_path, mode, election_type, elliptic_curve, n_bits, n_digits, named_params)
    if input_file == None:
        create_sage_file(base_path, file_prefix, elliptic_curve, election_type, n_bits, named_params)
    non_linear_constraints, linear_constraints = compile_circuit(base_path, file_prefix, snark, input_file)
    constraints = non_linear_constraints + linear_constraints
    t_prep, crs_size = prepare_proof(snark, base_path, file_prefix)
    t_prove = prove(snark, base_path, file_prefix)
    t_ver = verify_proof(snark, base_path, file_prefix)
    export_results(snark, elliptic_curve, mode, election_type, n_bits, named_params, non_linear_constraints, linear_constraints, crs_size, t_prep, t_prove, t_ver)
    cleanup(base_path)

if __name__ == "__main__":
    main()