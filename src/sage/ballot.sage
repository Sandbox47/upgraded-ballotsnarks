from sageImport import sage_import
import json
from JSON import JSONUtils
import random
sage_import('constants', fromlist=['BASE_FIELD', 'BASE_FIELD_P', 'CURVE_CHOSEN_SUBGROUP_ORDER'])
sage_import('projectivePoint', fromlist=['ProjectivePoint'])
sage_import('curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])

class Ballot():
    def __init__(self, votes, eegPubKey: EEGPubKey, pointClass=ProjectivePoint):
        self.ballot = votes
        self.checkIntegrity()
        # print(self.ballot)

        self.eegPubKey = eegPubKey
        self.r = self.genRandomness(self.ballot)
        self.g = self.eegPubKey.gen
        self.pk = self.eegPubKey.genTimesb

        self.gr = self.encrypt(self.ballot, self.r, onlyFirst=True)
        self.gv_pkr = self.encrypt(self.ballot, self.r, onlySecond=True)

    def genRandomness(self, array):
        """
        Generates an array with the same shape as the input array, filled with random numbers.
        """
        if isinstance(array, list):
            return [self.genRandomness(subarray) for subarray in array]
        else:
            return random.randint(0, self.eegPubKey.curve.chosenSubGroupOrder - 1)

    def checkIntegrity(self):
        raise NotImplementedError("This methods behaviour is specific to the ballot.")

    def generateRandomBallot(self):
        raise NotImplementedError("This methods behaviour is specific to the ballot.")

    def encrypt(self, votes, rands, onlyFirst=False, onlySecond=False):
        """
        Encrypts the entries in the votes object using the randomnesses in rands and the public key eegPubKey.
        """
        if isinstance(votes, list):
            return [self.encrypt(votes[i], rands[i], onlyFirst=onlyFirst, onlySecond=onlySecond) for i in range(len(votes))]
        else:
            ciphertext = EEG.encrypt(EEGPlaintext(votes), self.eegPubKey, rands)
            if onlyFirst:
                return ciphertext.genTimesRand
            elif onlySecond:
                return ciphertext.genTimesPlainPlusGenTimesbTimesRand
            # print(str(onlyFirst), str(onlySecond))
            return ciphertext.genTimesRand, ciphertext.genTimesPlainPlusGenTimesbTimesRand

    def toJSON(self):
        data = {
                "g": self.eegPubKey.gen.toJSON(),
                "pk": self.eegPubKey.genTimesb.toJSON(),
                "ballot": JSONUtils.arrayToJSON(self.ballot),
                "r": JSONUtils.arrayToJSON(self.r),

                "enc_gr": JSONUtils.arrayToJSON(self.gr),
                "enc_gv_pkr": JSONUtils.arrayToJSON(self.gv_pkr)
        }
        print(self.ballot)
        return data

class SingleVoteBallot(Ballot):
    def __init__(self, votes, eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)

    def checkIntegrity(self):
        sumVotes = 0
        for vote in self.ballot:
            sumVotes += vote
            if vote != 0 and vote != 1:
                raise ValueError(f"Vote must be binary but is {vote}.")
        if sumVotes != 0 and sumVotes != 1:
            raise ValueError(f"Sum of all votes must be binary but is {sumVotes}.")

    @classmethod
    def generateRandomBallot(cls, nVotes: int, eegPubKey: EEGPubKey):
        votes = [0 for i in range(nVotes)]
        posOneVote = random.randint(0, (nVotes * 6) // 5) # 0.2 Probability of abstention
        if posOneVote < nVotes:
            votes[posOneVote] = 1
        # print(str(votes))
        return SingleVoteBallot(votes, eegPubKey)

curve = MontgomeryCurve()
eegKey = EEGKey(curve)

singleVoteBallot = SingleVoteBallot.generateRandomBallot(10, eegKey.pubKey)

print(json.dumps(singleVoteBallot.toJSON(), indent=4))