from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

class PointlistBordaBallot(Ballot):
    def __init__(self, votes, orderedPoints: list[int], eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.orderedPoints = orderedPoints
        self.checkIntegrity()

    def checkIntegrity(self):
        for points in self.orderedPoints:
            count = self.ballot.count(points)
            if count != 1:
                raise ValueError(f"{points} points have been given to {count} candiadates but should be given to exactly one candidate.")

        expectedZeros = len(self.ballot) - len(self.orderedPoints)
        count = self.ballot.count(0)
        if count != expectedZeros:
            raise ValueError(f"0 points have been given to {count} candiadates but should be given to exactly {expectedZeros} candidates.")

    @classmethod
    def generateRandomBallot(cls, nCand: int, nPoints: int, orderedPoints: list[int], eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        votes = [0 for i in range(nCand)]
        indices = set([i for i in range(nCand)])
        for points in orderedPoints:
            index = random.choice(list(indices))
            indices.remove(index)
            votes[index] = points
        return PointlistBordaBallot(votes, orderedPoints, eegPubKey)