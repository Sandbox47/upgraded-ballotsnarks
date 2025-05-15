from sageImport import sage_import
import random
import json
sage_import('../EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])
sage_import('multiVote', fromlist=['MultiVoteBallot'])
sage_import('../constants', fromlist=['BITS_PLAIN'])

"""
Multi vote with the additional constraint that the product of the second and third entry has to equal the first one.
"""
class MultiVoteWithRulesBallot(MultiVoteBallot):
    def __init__(self, votes, maxVotesCand: int, maxChoices: int, eegPubKey: EEGPubKey):
        super().__init__(votes, maxVotesCand, maxChoices, eegPubKey)
        self.checkIntegrity()

    def checkIntegrity(self):
        super().checkIntegrity()
        if self.ballot[0] != self.ballot[1] * self.ballot[2]:
            raise ValueError(f"Product of second and third vote must equal first vote but is: {self.ballot[1]} * {self.ballot[2]} = {self.ballot[1] * self.ballot[2]} != {self.ballot[0]}.")

    @classmethod
    def generateRandomBallot(cls, nVotes: int, maxVotesCand: int, maxChoices: int, eegPubKey: EEGPubKey, bitsPlain=BITS_PLAIN):
        if nVotes < 3:
            raise ValueError("Need at least 3 entries in the ballot to enforce the additional constraint on the first three votes.")
        restVotes = maxChoices
        votes = [None]

        # Second entry:
        vote = random.randint(0, min(maxVotesCand, restVotes))
        votes.append(vote)
        restVotes -= vote

        # Third entry:
        # We know:  restVotes - votes[2] - votes[0] >= 0
        #       ->  restVotes - votes[2] - votes[1]*votes[2] >= 0
        #       ->  restVotes - (votes[1] + 1)*votes[2] >= 0
        #       ->  votes[2] <= restVotes/(votes[1] + 1)
        #
        # Also:     votes[0] <= maxVotesCand
        #       ->  votes[1] * votes[2] <= maxVotesCand
        #       ->  votes[2] <= maxVotesCand/votes[1]
        #
        # And:      votes[2] <= maxVotesCand
        vote = random.randint(0, min(maxVotesCand//max(1, votes[1]), restVotes//(votes[1] + 1)))
        votes.append(vote)
        restVotes -= vote

        # First entry:
        vote = votes[1] * votes[2]
        votes[0] = vote
        restVotes -= vote

        # Other entries:
        for i in range(nVotes - 3):
            vote = random.randint(0, min(maxVotesCand, restVotes))
            votes.append(vote)
            restVotes -= vote
        return MultiVoteWithRulesBallot(votes, maxVotesCand, maxChoices, eegPubKey)