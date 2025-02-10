import json
import sys
import os

testSuitePath = sys.argv[1]
with open(testSuitePath) as testSuiteFile:
    testSuite = json.load(testSuiteFile)
    for test in testSuite:
        commandStr = test.get("command")
        if commandStr != None:
            os.system(commandStr)
        else:
            raise SyntaxError("Test does not contain a command.")

