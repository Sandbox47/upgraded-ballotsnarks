from sageImport import sage_import
import json
from JSON import JSONUtils
import random
sage_import('../constants', fromlist=['BASE_FIELD', 'BASE_FIELD_P', 'CURVE_CHOSEN_SUBGROUP_ORDER'])
sage_import('../projectivePoint', fromlist=['ProjectivePoint'])
sage_import('../curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])

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
        raise NotImplementedError("This methods behaviour is specific to the ballot type.")

    @classmethod
    def generateRandomBallot(cls):
        raise NotImplementedError("This methods behaviour is specific to the ballot type.")

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
        # print(self.ballot)
        return data

    @classmethod
    def test(cls, ballotType, eegKey=None, **kwargs):
        """
        Sets up Montgomery curve and a corresponding EEGKey. 
        Then calls the generateRandomBallot Method of the specified ballotType and outputs the ballot in JSON format.

        :param ballotType: Reference to Ballot subclass
        :param EEGKey eegKey: Exponential ElGamal key to be used (randomly chosen if none is provided)
        :param **kwargs: Specification of charactersitics of the generated ballot (e.g., size)
        """
        if eegKey==None:
            curve = MontgomeryCurve()
            eegKey = EEGKey(curve)
        else:
            curve = eegKey.pubKey.curve

        if hasattr(ballotType, 'generateRandomBallot'):
            method = getattr(ballotType, 'generateRandomBallot')
            if callable(method):
                ballot = method(**kwargs, eegPubKey=eegKey.pubKey)
            else:
                raise TypeError(f"'{method}' is not callable on {ballotType.__name__}.")
        else:
            raise AttributeError(f"'{ballotType.__name__}' does not have a method named '{method}'.")

        print(json.dumps(ballot.toJSON(), indent=4))
