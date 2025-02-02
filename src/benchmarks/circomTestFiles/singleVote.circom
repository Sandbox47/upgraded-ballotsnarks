pragma circom 2.2.1;

include "../../voting/singleVote.circom";

component main {public [g, pk, enc_gr, enc_gv_pkr]} = assertSingleVote(32, 255, 126932, 1, 50);
