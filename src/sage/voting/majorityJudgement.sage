from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('singleVote', fromlist=['SingleVoteBallot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

class MajorityJudgementBallot(Ballot):
    def __init__(self, votes, nCand: int, nGrades: int, eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.nCand = nCand
        self.nGrades = nGrades
        self.checkIntegrity()

    def checkIntegrity(self):
        for candidateGrades in self.ballot:
            sumVotes = 0
            for vote in candidateGrades:
                sumVotes += vote
                if vote != 0 and vote != 1:
                    raise ValueError(f"Vote must be binary but is {vote}.")
            if sumVotes != 1:
                raise ValueError(f"Each candidate must receive exactly one grade but got {sumVotes} grades.")

    @classmethod
    def generateRandomBallot(cls, nCand: int, nGrades: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        votes = [[0 for j in range(nGrades)] for i in range(nCand)]
        for i in range(nCand):
            posOneVote = random.randint(0, nGrades - 1)
            votes[i][posOneVote] = 1
        return MajorityJudgementBallot(votes, nCand, nGrades, eegPubKey)
