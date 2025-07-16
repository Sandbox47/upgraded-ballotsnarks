from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

class BordaTournamentStyleBallot(Ballot):
    def __init__(self, votes, nVotes: int, ranking: list[int], a: int, b: int, eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.nVotes = nVotes
        self.ranking = ranking
        self.a = a
        self.b = b
        self.checkIntegrity()

    def checkIntegrity(self):
        votes = BordaTournamentStyleBallot.computeVotesFromRanking(self.ranking, self.nVotes, self.a, self.b)
        for i in range(self.nVotes):
            if self.ballot[i] != votes[i]:
                raise ValueError(f"Ballot belonging to the ranking does not match provided ballot. Mismatch at position {i}: Computed is {votes[i]}, provided is {self.ballot[i]}.")

    @classmethod
    def computeVotesFromRanking(cls, ranking: list[int], nVotes: int, a: int, b: int):
        votes = [0 for i in range(nVotes)]
        for i in range(nVotes):
            countRankedWorse = sum((entry > ranking[i]) for entry in ranking)
            countRankedTheSame = sum((entry == ranking[i]) for entry in ranking)
            votes[i] = a * countRankedWorse + b * (countRankedTheSame - 1) # (... -1) to exclude the entry at position i
        return votes

    @classmethod
    def generateRandomBallot(cls, nVotes: int, a:int, b: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        ranking = Ballot.generateRandomRanking(nVotes)
        votes = BordaTournamentStyleBallot.computeVotesFromRanking(ranking, nVotes, a, b)
        return BordaTournamentStyleBallot(votes, nVotes, ranking, a, b, eegPubKey)