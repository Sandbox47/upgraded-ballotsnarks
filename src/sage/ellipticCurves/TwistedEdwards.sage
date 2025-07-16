from sageImport import sage_import
from typing import Type
import json
from JSON import JSONUtils
sage_import('../constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'MONTGOMERY_CURVE_A', 'MONTGOMERY_CURVE_B', 'TWISTED_EDWARDS_CURVE_a', 'TWISTED_EDWARDS_CURVE_d', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])
sage_import('curve', fromlist=['CurvePoint'])
sage_import('ShortWeierstrass', fromlist=['ShortWeierstrassPoint'])
sage_import('Montgomery', fromlist=['MontgomeryAffinePoint', 'MontgomeryProjectivePoint'])

class TwistedEdwardsPoint(CurvePoint):
    def __init__(self, x: BASE_FIELD, y: BASE_FIELD, a: BASE_FIELD=TWISTED_EDWARDS_CURVE_a, d: BASE_FIELD=TWISTED_EDWARDS_CURVE_d, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        super().__init__([x,y], [a,d], chosenSubgroupOrder=chosenSubgroupOrder, name=name)
        self.x = BASE_FIELD(x)
        self.y = BASE_FIELD(y)
        self.a = BASE_FIELD(a)
        self.d = BASE_FIELD(d)

    @classmethod
    def getInfinity(cls, curveParams: list=None, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        if curveParams == None:
            return TwistedEdwardsPoint(0, 1, chosenSubgroupOrder=chosenSubgroupOrder, name=name)
        if len(curveParams) != 2:
            raise AttributeError(f"You provided {len(curveParams)} curve parameters but {2} are required")
        return TwistedEdwardsPoint(0, 1, curveParams[0], curveParams[1], chosenSubgroupOrder=chosenSubgroupOrder, name=name)

    def toJSON(self):
        innerData = {
            "x": str(self.x),
            "y": str(self.y)
        }
        return JSONUtils.toJSON(self, innerData)
    
    def castToShortWeierstrassPoint(self):
        selfM = self.castToMontgomeryAffinePoint()
        return selfM.castToShortWeierstrassPoint()

    def castToMontgomeryProjectivePoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castToMontgomeryAffinePoint(self):
        """
        Map a point from Montgomery form to TwistedEdwards form. (Montgomery curves and their arithmetic, Section 2.5)
        """
        A = 2*((self.a+self.d)/(self.a-self.d))
        B = 4/(self.a-self.d)
        # print(self)
        if not (self.x == BASE_FIELD(0) and self.y == BASE_FIELD(1)): # Not infinity
            return MontgomeryAffinePoint((1+self.y)/(1-self.y), (1+self.y)/((1-self.y)*self.x), True, A, B, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name)
        else:
            return MontgomeryAffinePoint(0, 0, False, A, B, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name)

    def castFromShortWeierstrassPoint(self, other):
        otherM = self.castToMontgomeryAffinePoint().castFromShortWeierstrassPoint(other)
        return self.castFromMontgomeryAffinePoint(otherM)

    def castFromMontgomeryProjectivePoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFromMontgomeryAffinePoint(self, other):
        """
        Map a point from Montgomery form to TwistedEdwards form. (Montgomery curves and their arithmetic, Section 2.5)
        """
        a = (other.A + 2)/other.B
        d = (other.A - 2)/other.B
        if other.notInfty:
            return TwistedEdwardsPoint(other.x/other.y, (other.x-1)/(other.x+1), a, d, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)
        else: # Infinity
            return TwistedEdwardsPoint(0, 1, a, d, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)
