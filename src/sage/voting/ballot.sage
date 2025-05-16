from sageImport import sage_import
import json
from JSON import JSONUtils
import random
import math
sage_import('../constants', fromlist=['BASE_FIELD', 'BASE_FIELD_P', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'BITS_RAND', 'BITS_PLAIN', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])
sage_import('../ellipticCurves/curve', fromlist=['CurvePoint'])
sage_import('../ellipticCurves/Montgomery', fromlist=['MontgomeryAffinePoint', 'MontgomeryProjectivePoint'])
sage_import('../ellipticCurves/TwistedEdwards', fromlist=['TwistedEdwardsPoint'])
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])

class Ballot():
    def __init__(self, votes, eegPubKey: EEGPubKey, bitsRand=BITS_RAND, bitsPlain=BITS_PLAIN):
        self.ballot = votes
        digitsPlain = math.ceil(bitsPlain/math.log(TE_ENC_BASE, 2))
        self.ballot_indices = self.genBaseIndices(self.ballot, digitsPlain)
        self.ranking = None

        self.eegPubKey = eegPubKey
        self.r = self.genRandomness(self.ballot)
        self.r_indices = self.genBaseIndices(self.r, DIGITS_RAND)
        self.g = self.eegPubKey.gen
        self.pk = self.eegPubKey.genTimesb
        self.powersOfg = self.g.genMultiples(DIGITS_RAND)
        self.powersOfpk = self.pk.genMultiples(DIGITS_RAND)

        self.gr = self.encrypt(self.ballot, self.r, onlyFirst=True)
        self.gv_pkr = self.encrypt(self.ballot, self.r, onlySecond=True)

    def genRandomness(self, array):
        """
        Generates an array with the same shape as the input array, filled with random numbers.
        """
        if isinstance(array, list):
            return [self.genRandomness(subarray) for subarray in array]
        else:
            return random.randint(0, self.eegPubKey.gen.chosenSubgroupOrder - 1)

    def checkIntegrity(self):
        raise NotImplementedError("This methods behaviour is specific to the ballot type.")

    @classmethod
    def toBaseIndices(cls, number, digits):
        base_indices=[]
        original_number = number
        for j in range(0, digits):
            digit_indices = [0 for i in range(0, TE_ENC_BASE)]
            digit = Integer(str(number)) % TE_ENC_BASE
            digit_indices[digit] = 1
            number = Integer(str(number)) // TE_ENC_BASE
            base_indices.append(digit_indices)
        return base_indices

    def genBaseIndices(self, array, digits):
        """
        Generates an array with the same shape as the input array, filled with random numbers.
        """
        if isinstance(array, list):
            return [self.genBaseIndices(subarray, digits) for subarray in array]
        else:
            return Ballot.toBaseIndices(array, digits)

    @classmethod
    def generateRandomBallot(cls):
        raise NotImplementedError("This methods behaviour is specific to the ballot type.")

    @classmethod
    def generateRandomRanking(cls, n):
        """
        Generates a ranking with potential ties at arbitrary places
        """
        ranking = [random.randint(0, n - 1) for i in range(n)]
        print(ranking)
        return ranking

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
            return ciphertext.genTimesRand, ciphertext.genTimesPlainPlusGenTimesbTimesRand

    def toJSON(self):
        data = {
                "ballot": JSONUtils.arrayToJSON(self.ballot),

                "enc_gr": JSONUtils.arrayToJSON(self.gr),
                "enc_gv_pkr": JSONUtils.arrayToJSON(self.gv_pkr)
        }
        typeName = type(self.g).__name__  # Get class name as a string
        if typeName == "TwistedEdwardsPoint":
            data["powersOfg"] = JSONUtils.arrayToJSON(self.powersOfg)
            data["powersOfpk"] = JSONUtils.arrayToJSON(self.powersOfpk)
            data["ballot_for_enc"] = JSONUtils.arrayToJSON(self.ballot_indices)
            data["r"] = JSONUtils.arrayToJSON(self.r_indices)
        elif typeName == "MontgomeryAffinePoint" or typeName == "MontgomeryProjectivePoint":
            data["g"] = self.g.toJSON()
            data["pk"] = self.pk.toJSON()
            data["ballot_for_enc"] = JSONUtils.arrayToJSON(self.ballot)
            data["r"] = JSONUtils.arrayToJSON(self.r)

        else:
            raise TypeError(f"No circom implementation for elliptic curve of type {type(self.g)}.")

        if self.ranking != None:
            data["ranking"] = JSONUtils.arrayToJSON(self.ranking)
        return data

    @classmethod
    def test(cls, ballotType, curvePointClass, bitsPlain, eegKey=None, **kwargs):
        """
        Sets up Montgomery curve and a corresponding EEGKey. 
        Then calls the generateRandomBallot Method of the specified ballotType and outputs the ballot in JSON format.

        :param ballotType: Reference to Ballot subclass
        :param EEGKey eegKey: Exponential ElGamal key to be used (randomly chosen if none is provided)
        :param **kwargs: Specification of charactersitics of the generated ballot (e.g., size)
        """
        if eegKey==None:
            eegKey = EEGKey(curvePointClass)
            print(f"EEGKey gnerated:\n{eegKey}")

        if hasattr(ballotType, 'generateRandomBallot'):
            method = getattr(ballotType, 'generateRandomBallot')
            if callable(method):
                ballot = method(**kwargs, eegPubKey=eegKey.pubKey, bitsPlain=bitsPlain)
            else:
                raise TypeError(f"'{method}' is not callable on {ballotType.__name__}.")
        else:
            raise AttributeError(f"'{ballotType.__name__}' does not have a method named '{method}'.")

        print(json.dumps(ballot.toJSON(), indent=4))
