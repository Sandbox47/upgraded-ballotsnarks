from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('ballot', fromlist=['Ballot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

class LineVoteBallot(Ballot):
    def __init__(self, votes, eegPubKey: EEGPubKey):
        super().__init__(votes, eegPubKey)
        self.checkIntegrity()

    def checkIntegrity(self):
        zeroOneChanges = self.ballot[0]
        for i in range(1, len(self.ballot)):
            vote = self.ballot[i]
            if self.ballot[i - 1] == 0 and vote == 1:
                zeroOneChanges += 1 # Add 1 if if there is a change from 0 to 1, leave unchanged otherwise
            if vote != 0 and vote != 1:
                raise ValueError(f"Vote must be binary but is {vote}.")
        if zeroOneChanges > 1:
            raise ValueError(f"All 1 votes must be consecutive.")

    @classmethod
    def generateRandomBallot(cls, nVotes: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        votes = [0 for i in range(nVotes)]
        posOneVotesStart = random.randint(0, nVotes - 1)
        posOneVotesEnd = random.randint(0, nVotes - 1)
        if posOneVotesStart <= posOneVotesEnd: # Otherwise: Abstention
            for i in range(posOneVotesStart, posOneVotesEnd + 1):
                votes[i] = 1
        return LineVoteBallot(votes, eegPubKey)