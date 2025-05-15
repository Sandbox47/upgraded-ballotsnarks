from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('../constants', fromlist=['BITS_PLAIN'])
sage_import('ballot', fromlist=['Ballot'])

class SingleVoteBallot(Ballot):
    def __init__(self, votes, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        super().__init__(votes, eegPubKey, bitsPlain=bitsPlain)
        self.checkIntegrity()

    def checkIntegrity(self):
        sumVotes = 0
        for vote in self.ballot:
            sumVotes += vote
            if vote != 0 and vote != 1:
                raise ValueError(f"Vote must be binary but is {vote}.")
        if sumVotes != 0 and sumVotes != 1:
            raise ValueError(f"Sum of all votes must be binary but is {sumVotes}.")

    @classmethod
    def generateRandomBallot(cls, nVotes: int, eegPubKey: EEGPubKey, bitsPlain):
        votes = [0 for i in range(nVotes)]
        # posOneVote = random.randint(0, (nVotes * 6) // 5) # 0.2 Probability of abstention
        posOneVote = random.randint(0, nVotes) # No abstention
        if posOneVote < nVotes:
            votes[posOneVote] = 1
        print(str(votes))
        return SingleVoteBallot(votes, eegPubKey, bitsPlain=bitsPlain)