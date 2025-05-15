from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

class MultiVoteBallot(Ballot):
    def __init__(self, votes, maxVotesCand: int, maxChoices: int, eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.maxVotesCand = maxVotesCand
        self.maxChoices = maxChoices
        self.checkIntegrity()

    def checkIntegrity(self):
        sumVotes = 0
        for vote in self.ballot:
            sumVotes += vote
            if vote < 0 or vote > self.maxVotesCand:
                raise ValueError(f"Vote must be in [0, {self.maxVotesCand}] but is {vote}.")
        if sumVotes > self.maxChoices:
            raise ValueError(f"Sum of all votes must be in [0, {self.maxChoices}] but is {sumVotes}.")

    @classmethod
    def generateRandomBallot(cls, nVotes: int, maxVotesCand: int, maxChoices: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        restVotes = maxChoices
        votes = []
        for i in range(nVotes):
            vote = random.randint(0, min(maxVotesCand, restVotes))
            votes.append(vote)
            restVotes -= vote
        return MultiVoteBallot(votes, maxVotesCand, maxChoices, eegPubKey)