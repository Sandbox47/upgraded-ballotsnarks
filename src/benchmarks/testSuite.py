import json
from JSON import JSONUtils

class Test():
    def __init__(self, name: str, bitsVotes: str, nCand: str, nCandName: str, additionalParams: list[tuple[str, int]]):
        self.name = name
        self.bitsVotes = bitsVotes
        self.nCand = nCand
        self.nCandName = nCandName
        self.additionalParams = additionalParams

    def getBenchmarkCommand(self):
        command = "./benchmark.sh " + str(self.name) + " " + str(self.bitsVotes) + " " + str(self.nCandName) + "=" + str(self.nCand)
        for param in self.additionalParams:
            command += " " + str(param[0]) + "=" + str(param[1])
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
    def __init__(self, bitsVotes: int, nCand: int):
        super().__init__("singleVote", bitsVotes, nCand, "nVotes", [])

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int):
        return [SingleVoteTest(bitsVotes, nCand)]
    
class PointlistBordaTest(Test):
    def __init__(self, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__("pointlistBorda", bitsVotes, nCand, "nCand", additionalParams)

    @classmethod
    def generatePointlist(cls, length: int):
        return [points for points in range(length, 0, -1)]

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        defaultPointlistLength = electionTypeConfig["defaultPointlistLength"]
        testCases = []
        if electionTypeConfig["doPointlistLengthEqualsChoicesCase"]:
            pointlistnCandLength = PointlistBordaTest.generatePointlist(nCand)
            testCases.append(PointlistBordaTest(bitsVotes, nCand, [("nPoints", nCand), ("orderedPoints", pointlistnCandLength)]))
        if nCand >= defaultPointlistLength:
            pointlistDefaultLength = PointlistBordaTest.generatePointlist(defaultPointlistLength)
            testCases.append(PointlistBordaTest(bitsVotes, nCand, [("nPoints", defaultPointlistLength), ("orderedPoints", pointlistDefaultLength)]))
        return testCases
    
class MultiVoteTest(Test):
    def __init__(self, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__("multiVote", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        maxChoices = electionTypeConfig["maxChoices"]
        if maxChoices == "calculated from nCand":
            maxChoices = 2*nCand # Default value
        maxVotesCand = electionTypeConfig["maxVotesCand"]
        if maxVotesCand == "default":
            maxVotesCand = 5 # Default value
        return [MultiVoteTest(bitsVotes, nCand, [("maxChoices", maxChoices), ("maxVotesCand", maxVotesCand)])]
    
class MultiVoteWithRulesTest(Test):
    def __init__(self, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__("multiVoteWithRules", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        maxChoices = electionTypeConfig["maxChoices"]
        if maxChoices == "calculated from nCand":
            maxChoices = 2*nCand # Default value
        maxVotesCand = electionTypeConfig["maxVotesCand"]
        if maxVotesCand == "default":
            maxVotesCand = 5 # Default value
        return [MultiVoteWithRulesTest(bitsVotes, nCand, [("maxChoices", maxChoices), ("maxVotesCand", maxVotesCand)])]
    
class MajorityJudgementTest(Test):
    def __init__(self, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__("majorityJudgement", bitsVotes, nCand, "nCand", additionalParams)

    @classmethod
    def generatePointlist(cls, length: int):
        return [points for points in range(length, 0, -1)]

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        defaultnGrades = electionTypeConfig["defaultNumberOfGrades"]

        testCases = []
        if electionTypeConfig["doNumberOfGradesEqualsCandsCase"]:
            nGrades = nCand
            testCases.append(MajorityJudgementTest(bitsVotes, nCand, [("nGrades", nGrades)]))

        testCases.append(MajorityJudgementTest(bitsVotes, nCand, [("nGrades", defaultnGrades)]))
        return testCases
    
class LineVoteTest(Test):
    def __init__(self, bitsVotes: int, nCand: int):
        super().__init__("lineVote", bitsVotes, nCand, "nVotes", [])

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int):
        return [LineVoteTest(bitsVotes, nCand)]
    
class CondorcetTest(Test):
    def __init__(self, bitsVotes: int, nCand: int):
        super().__init__("condorcet", bitsVotes, nCand, "nCand", [])

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int):
        return [CondorcetTest(bitsVotes, nCand)]
    
class BordaTournamentStyleTest(Test):
    def __init__(self, bitsVotes: int, nCand: int, additionalParams: list[tuple[str, int]]):
        super().__init__("bordaTournamentStyle", bitsVotes, nCand, "nVotes", additionalParams)

    @classmethod
    def generateTestCases(cls, bitsVotes: int, nCand: int, electionTypeConfig: dict):
        a = electionTypeConfig["a"]
        b = electionTypeConfig["b"]
        testCases = [BordaTournamentStyleTest(bitsVotes, nCand, [("a", a), ("b", b)])]
        return testCases

class TestSuite():
    def __init__(self, testConfig: dict):
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
                    self.testCases += TestSuite.generateTestCases(electionType, bitsVotes, nCand, electionTypeConfig)

    @classmethod
    def generateTestCases(cls, electionType: str, bitsVotes: int, nCand: int, electionTypeConfig: dict=None):
        testClassName = electionType[:1].upper() + electionType[1:] + "Test"
        testClass = globals()[testClassName]
        if electionTypeConfig == None:
            testCases = testClass.generateTestCases(bitsVotes, nCand)
        else:
            testCases = testClass.generateTestCases(bitsVotes, nCand, electionTypeConfig)
        return testCases
    
    def toJSON(self):
        return JSONUtils.arrayToJSON(self.testCases)


def genTestSuite():
    with open('testConfig.json') as testConfigFile:
        testConfig = json.load(testConfigFile)
        testSuite = TestSuite(testConfig)
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
        with open('testSuite.json', 'w') as testSuiteFile:
            testSuiteFile.write(jsonStr)

genTestSuite()