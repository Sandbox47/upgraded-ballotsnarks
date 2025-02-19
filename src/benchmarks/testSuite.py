import json
from JSON import JSONUtils

class Test():
    def __init__(self, testCircuit: str, name: str, bitsVotes: str, nCand: str, nCandName: str, additionalParams: list[tuple[str, int]]):
        self.testCircuit = testCircuit
        self.name = name
        self.bitsVotes = bitsVotes
        self.nCand = nCand
        self.nCandName = nCandName
        self.additionalParams = additionalParams

    def getBenchmarkCommand(self):
        command = "./benchmark.sh " + str(self.testCircuit) + " " + str(self.name) + " " + str(self.bitsVotes) + " " + str(self.nCandName) + "=" + str(self.nCand)
        for param in self.additionalParams:
            command += " " + str(param[0]) + "=" + str(param[1]).replace(" ", "")
        return command

    def toJSON(self):
        data = {
            "name": self.name,
            "bitsVotes": self.bitsVotes,
            str(self.nCandName): self.nCand,
        }
        additionaParamsData = {}
        for param in self.additionalParams:
            additionaParamsData[param[0]] = param[1]
        data = data | additionaParamsData
        data["command"] = self.getBenchmarkCommand()
        return data
    
    @classmethod
    def generateTestCases(cls):
        raise NotImplementedError("Behaviour is specific to the subclassses.")

    
class SingleVoteTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int):
        super().__init__(testCircuit, "singleVote", bitsVotes, nCand, "nVotes", [])

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int):
        return [SingleVoteTest(testCircuit, bitsVotes, nCand)]
    
class PointlistBordaTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__(testCircuit, "pointlistBorda", bitsVotes, nCand, "nCand", additionalParams)

    @classmethod
    def generatePointlist(cls, length: int):
        return [points for points in range(length, 0, -1)]

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        defaultPointlistLength = electionTypeConfig["defaultPointlistLength"]
        testCases = []
        if electionTypeConfig["doPointlistLengthEqualsChoicesCase"]:
            pointlistnCandLength = PointlistBordaTest.generatePointlist(nCand)
            testCases.append(PointlistBordaTest(testCircuit, bitsVotes, nCand, [("nPoints", nCand), ("orderedPoints", pointlistnCandLength)]))
        if nCand >= defaultPointlistLength:
            pointlistDefaultLength = PointlistBordaTest.generatePointlist(defaultPointlistLength)
            testCases.append(PointlistBordaTest(testCircuit, bitsVotes, nCand, [("nPoints", defaultPointlistLength), ("orderedPoints", pointlistDefaultLength)]))
        return testCases
    
class MultiVoteTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__(testCircuit, "multiVote", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        maxChoices = electionTypeConfig["maxChoices"]
        if maxChoices == "calculated from nCand":
            maxChoices = 2*nCand # Default value
        maxVotesCand = electionTypeConfig["maxVotesCand"]
        return [MultiVoteTest(testCircuit, bitsVotes, nCand, [("maxVotesCand", maxVotesCand), ("maxChoices", maxChoices)])]
    
class MultiVoteWithRulesTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__(testCircuit, "multiVoteWithRules", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        maxChoices = electionTypeConfig["maxChoices"]
        if maxChoices == "calculated from nCand":
            maxChoices = 2*nCand # Default value
        maxVotesCand = electionTypeConfig["maxVotesCand"]
        if nCand >= 3: # Need at least three entries to enforce the additional rule
            return [MultiVoteWithRulesTest(testCircuit, bitsVotes, nCand, [("maxVotesCand", maxVotesCand), ("maxChoices", maxChoices)])]
        else:
            return []
    
class MajorityJudgementTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__(testCircuit, "majorityJudgement", bitsVotes, nCand, "nCand", additionalParams)

    @classmethod
    def generatePointlist(cls, length: int):
        return [points for points in range(length, 0, -1)]

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        defaultnGrades = electionTypeConfig["defaultNumberOfGrades"]

        testCases = []
        if electionTypeConfig["doNumberOfGradesEqualsCandsCase"]:
            nGrades = nCand
            testCases.append(MajorityJudgementTest(testCircuit, bitsVotes, nCand, [("nGrades", nGrades)]))

        testCases.append(MajorityJudgementTest(testCircuit, bitsVotes, nCand, [("nGrades", defaultnGrades)]))
        return testCases
    
class LineVoteTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int):
        super().__init__(testCircuit, "lineVote", bitsVotes, nCand, "nVotes", [])

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int):
        return [LineVoteTest(testCircuit, bitsVotes, nCand)]
    
class CondorcetTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int):
        super().__init__(testCircuit, "condorcet", bitsVotes, nCand, "nCand", [])

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int):
        return [CondorcetTest(testCircuit, bitsVotes, nCand)]
    
class BordaTournamentStyleTest(Test):
    def __init__(self, testCircuit: str, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__(testCircuit, "bordaTournamentStyle", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, testCircuit: str, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        a = electionTypeConfig["a"]
        b = electionTypeConfig["b"]
        testCases = [BordaTournamentStyleTest(testCircuit, bitsVotes, nCand, [("a", a), ("b", b)])]
        return testCases

class TestSuite():
    def __init__(self, testConfig: dict, testCircuit: str):
        self.testCircuit = testCircuit
        testSuiteData = testConfig["testSuite"]
        electionTypeConfigs = testConfig["electionTypeSpecificConfigs"]

        self.bitsVotes = testSuiteData["bitsVotes"]
        self.nCand = testSuiteData["nCand"]
        self.electionTypes = testSuiteData["electionTypes"]

        self.testCases = []
        for electionType in self.electionTypes:
            electionTypeConfig = electionTypeConfigs.get(electionType)
            for bitsVotes in self.bitsVotes:
                for nCand in self.nCand:
                    self.testCases += TestSuite.generateTestCases(testCircuit, electionType, bitsVotes, nCand, electionTypeConfig)

    @classmethod
    def generateTestCases(cls, testCircuit: str, electionType: str, bitsVotes: int, nCand: int, electionTypeConfig: dict=None):
        testClassName = electionType[:1].upper() + electionType[1:] + "Test"
        testClass = globals()[testClassName]
        if electionTypeConfig == None:
            testCases = testClass.generateTestCases(testCircuit, bitsVotes, nCand)
        else:
            testCases = testClass.generateTestCases(testCircuit, bitsVotes, nCand, electionTypeConfig)
        return testCases
    
    def toJSON(self):
        return JSONUtils.arrayToJSON(self.testCases)


def genTestSuites():
    with open('testConfig.json') as testConfigFile:
        testConfig = json.load(testConfigFile)
        testSuite = testConfig["testSuite"]
        testCircuits = testSuite["testCircuits"]

        for testCircuit in testCircuits:
            testSuite = TestSuite(testConfig, testCircuit)
            testSuiteJSONData = testSuite.toJSON()

            # Convert to JSON string with indentation
            jsonStr = json.dumps(testSuiteJSONData, indent=4)

            # Format orderedPoints array to be in one line
            for test in testSuiteJSONData:
                if test.get("orderedPoints") != None:
                    formattedList = json.dumps(test["orderedPoints"])  # Single-line array
                    originalList = json.dumps(test["orderedPoints"], indent=12)  # Multi-line array
                    originalList = originalList[:-1] + "        ]"

                    # Ensure proper replacement with indentation handling
                    jsonStr = jsonStr.replace(originalList, formattedList)

            print(jsonStr)

            # Write to file
            testSuiteFilePath = 'testSuite' + str(testCircuit).capitalize() + '.json'
            with open(testSuiteFilePath, 'w') as testSuiteFile:
                testSuiteFile.write(jsonStr)

genTestSuites()