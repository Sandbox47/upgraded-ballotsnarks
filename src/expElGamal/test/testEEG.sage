from sageImport import sage_import
from JSON import JSONUtils
import random
sage_import('../../sage/constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT'])
sage_import('../../sage/curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('../../sage/affinePoint', fromlist=['AffinePoint'])
sage_import('../../sage/projectivePoint', fromlist=['ProjectivePoint'])
sage_import('../../sage/EEG', fromlist=['EEGPrivKey', 'EEGPubKey', 'EEGKey', 'EEGPlaintext', 'EEGCiphertext', 'EEGEncryption', 'EEGDecryption', 'EEG'])

def testEEGEncAffine():
    curve = MontgomeryCurve()
    gen = AffinePoint.getRandomPoint(curve)
    privKey = EEGPrivKey(curve, gen=gen)
    key = EEGKey(curve, privKey)
    plaintext = EEGPlaintext(random.randint(0, PLAINTEXT_LIMIT))
    encryption = EEGEncryption(plaintext, key.pubKey)
    # decryption = EEGDecryption(encryption.ciphertext, key.privKey)

    JSONUtils.exportToJSON(encryption.toJSON())

def testEEGEncProjective():
    curve = MontgomeryCurve()
    key = EEGKey(curve)
    plaintext = EEGPlaintext(random.randint(0, PLAINTEXT_LIMIT))
    encryption = EEGEncryption(plaintext, key.pubKey)
    # decryption = EEGDecryption(encryption.ciphertext, key.privKey)

    JSONUtils.exportToJSON(encryption.toJSON())

# testEEGEncAffine()
testEEGEncProjective()