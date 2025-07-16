from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])
sage_import('../ellipticCurves/TwistedEdwards', fromlist=['TwistedEdwardsPoint'])

class CondorcetBallot(Ballot):
    def __init__(self, votes, nCand: int, ranking: list[int], eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.nCand = nCand
        self.ranking = ranking
        self.checkIntegrity()

    def checkIntegrity(self):
        votes = CondorcetBallot.computeVotesFromRanking(self.ranking, self.nCand)
        for i in range(self.nCand):
            for j in range(self.nCand):
                if self.ballot[i][j] != votes[i][j]:
                    raise ValueError(f"Ballot belonging to the ranking does not match provided ballot. Mismatch at position ({i}, {j}): Computed is {votes[i][j]}, provided is {self.ballot[i][j]}.")

    @classmethod
    def computeVotesFromRanking(cls, ranking: list[int], nCand: int):
        votes = [[0 for j in range(nCand)] for i in range(nCand)]
        for i in range(nCand):
            for j in range(i+1, nCand):
                rankedTheSame = (ranking[i] == ranking[j])
                rankedWorse = (ranking[i] > ranking[j])
                if rankedWorse:
                    votes[i][j] = 0
                    votes[j][i] = 1
                elif rankedTheSame:
                    votes[i][j] = 0
                    votes[j][i] = 0
                else: # ranked better
                    votes[i][j] = 1
                    votes[j][i] = 0
        return votes

    @classmethod
    def generateRandomBallot(cls, nCand: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        ranking = Ballot.generateRandomRanking(nCand)
        votes = CondorcetBallot.computeVotesFromRanking(ranking, nCand)
        return CondorcetBallot(votes, nCand, ranking, eegPubKey)
