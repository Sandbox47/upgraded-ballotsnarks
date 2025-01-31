from sageImport import sage_import

sage_import('../../sage/voting/ballot', fromlist=['Ballot'])
sage_import('../../sage/voting/singleVote', fromlist=['SingleVoteBallot'])

Ballot.test(SingleVoteBallot, nVotes=1)
