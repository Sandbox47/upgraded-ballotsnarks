from sageImport import sage_import
import json
import random
sage_import('constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])
sage_import('ellipticCurves/curve', fromlist=['CurvePoint'])
sage_import('ellipticCurves/Montgomery', fromlist=['MontgomeryAffinePoint', 'MontgomeryProjectivePoint'])
sage_import('ellipticCurves/TwistedEdwards', fromlist=['TwistedEdwardsPoint'])

class EEGPrivKey():
    def __init__(self, curvePointClass, curveParams: list=None, b: BASE_FIELD=None, gen: CurvePoint=None):
        self.referencePoint = curvePointClass.getInfinity(curveParams=curveParams)
        self.gen = self.referencePoint.getGenerator() if gen == None else gen
        self.b = BASE_FIELD.random_element() if b == None else b

    def __str__(self):
        return f"Private Key (g, b) with:\ng ={self.gen}\nb ={self.b}"

class EEGPubKey():
    def __init__(self, privKey: EEGPrivKey):
        self.referencePoint = privKey.referencePoint
        self.gen = privKey.gen
        self.genTimesb = privKey.gen * privKey.b

    def __str__(self):
        return f"Public Key (g, g*b) with:\ng ={self.gen}\ng*b ={self.genTimesb}"

class EEGKey():
    def __init__(self, curvePointClass, curveParams: list=None,  privKey: EEGPrivKey=None):
        self.privKey = EEGPrivKey(curvePointClass, curveParams=curveParams) if privKey == None else privKey
        self.pubKey = EEGPubKey(self.privKey)

    def __str__(self):
        return f"Key:\n{self.privKey}\n{self.pubKey}"

class EEGPlaintext():
    def __init__(self, content: BASE_FIELD):
        if content < 0 or content > PLAINTEXT_LIMIT:
            raise ValueError(f"The plaintext must be in [0,{PLAINTEXT_LIMIT}].")
        self.content = content

    def __str__(self):
        return f"Plaintext p = {self.content}"

class EEGCiphertext():
    def __init__(self, genTimesRand: CurvePoint, genTimesPlainPlusGenTimesbTimesRand: CurvePoint):
        self.genTimesRand = genTimesRand
        self.genTimesPlainPlusGenTimesbTimesRand = genTimesPlainPlusGenTimesbTimesRand

    def __str__(self):
        return f"Ciphertext (g*r, (g*p)*(g*b*r)) with\ng*r ={self.genTimesRand}\n(g*p)*(g*b*r)={self.genTimesPlainPlusGenTimesbTimesRand}"

class EEGEncryption():
    def __init__(self, plaintext: EEGPlaintext, pubKey: EEGPubKey, rand: BASE_FIELD=None):
        self.plaintext = plaintext
        self.pubKey = pubKey
        self.rand = BASE_FIELD.random_element() if rand == None else rand

        self.ciphertext = EEGCiphertext(self.pubKey.gen * self.rand, self.pubKey.gen * self.plaintext.content + self.pubKey.genTimesb * self.rand)

    def __str__(self):
        return f"Encryption:\n{self.plaintext}\n{self.ciphertext}"

    def toJSON(self):
        # Convert the attributes to the correct format
        data = {
                "g": self.pubKey.gen.toJSON(),
                "pk": self.pubKey.genTimesb.toJSON(),
                "v": str(self.plaintext.content),
                "r": str(self.rand),
                "test_gr": self.ciphertext.genTimesRand.toJSON(),
                "test_gv_pkr": self.ciphertext.genTimesPlainPlusGenTimesbTimesRand.toJSON()
        }
        return data

class EEGDecryption():
    def __init__(self, ciphertext: EEGCiphertext, privKey: EEGPrivKey):
        self.ciphertext = ciphertext
        self.privKey = privKey
        
        genTimesPlain = (self.ciphertext.genTimesRand * self.privKey.b).__inv__() + self.ciphertext.genTimesPlainPlusGenTimesbTimesRand
        self.plaintext = EEGPlaintext(genTimesPlain.discreteLog(privKey.gen))

    def __str__(self):
        return f"Decryption:\n{self.plaintext}\n{self.ciphertext}"

class EEG():
    @classmethod
    def encrypt(cls, plaintext: EEGPlaintext, pubKey: EEGPubKey, rand: BASE_FIELD=None):
        rand = BASE_FIELD.random_element() if rand == None else rand
        return EEGCiphertext(pubKey.gen * rand, pubKey.gen * plaintext.content + pubKey.genTimesb * rand)

    @classmethod
    def decrypt(cls, ciphertext: EEGCiphertext, privKey: EEGPrivKey): # Ciphertext has format: (gen*rand, gen*plain + pubKey*rand)
        genTimesPlain = (ciphertext.genTimesRand * privKey.b).__inv__() + ciphertext.genTimesPlainPlusGenTimesbTimesRand
        return genTimesPlain.discreteLog(privKey.gen)

    @classmethod
    def encryptVector(cls, plaintexts, pubKey: EEGPubKey, rands=None):
        rands = [BASE_FIELD.random_element() for i in range(len(plaintexts))] if rands == None else rands
        return [EEG.encrypt(plaintexts[i], pubKey, rands[i]) for i in range(len(plaintexts))]

    @classmethod
    def decryptVector(cls, ciphertexts, privKey: EEGPrivKey):
        return [EEG.decrypt(ciphertext, privKey) for ciphertext in ciphertexts]

    @classmethod
    def encryptMatrix(cls, plaintexts, pubKey: EEGPubKey, rands=None):
        rands = [[BASE_FIELD.random_element() for j in range(len(plaintexts[0]))] for i in range(len(plaintexts))] if rands == None else rands
        return [EEG.encryptVector(plaintexts[i], pubKey, rands[i]) for i in range(len(plaintexts))]

    @classmethod
    def decryptMatrix(cls, ciphertexts, privKey: EEGPrivKey):
        return [EEG.decryptVector(ciphertextVector, privKey) for ciphertextVector in ciphertexts]
