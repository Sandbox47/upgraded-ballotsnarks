import json
import sys
import subprocess

testSuitePath = sys.argv[1]
log_file = "benchmark.log"
separator= "=" * 100

with open(log_file, "w") as f:
    with open(testSuitePath) as testSuiteFile:
        testSuite = json.load(testSuiteFile)
        for test in testSuite:
            commandStr = test.get("command")
            if commandStr != None:
                f.write("\n" + separator + "\n")
                print("\n" + separator)

                f.write(f"Executing: {commandStr}\n\n")
                print(f"Executing: {commandStr}\n")

                process = subprocess.Popen(
                    commandStr, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
                )

                # Read output line-by-line
                for line in process.stdout:
                    print(line, end="") # Print to terminal
                    f.write(line) # Write to log file


                process.wait() # Wait for the process to finish

            else:
                raise SyntaxError("Test does not contain a command.")

