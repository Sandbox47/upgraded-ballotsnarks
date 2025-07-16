from sageImport import sage_import
from typing import Type
sage_import('../constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'MONTGOMERY_CURVE_A', 'MONTGOMERY_CURVE_B', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])

class CurvePoint():
    def __init__(self, coordinates: list, curveParams: list, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        self.name = name
        self.curveParams = curveParams
        self.coordinates = coordinates
        self.chosenSubgroupOrder= chosenSubgroupOrder
    
    def __add__(self, other):
        """
        Used to execute the group law
        """
        selfSW = self.castTo("ShortWeierstrassPoint")
        otherSW = other.castTo("ShortWeierstrassPoint")

        resultSW = selfSW + otherSW

        return self.castFrom(resultSW)

    def __mul__(self, multiplier):
        """
        Scalar multiplication
        """
        resultSW = multiplier * self.castTo("ShortWeierstrassPoint")
        return self.castFrom(resultSW)

    def __rmul__(self, multiplier):
        return self.__mul__(multiplier)

    def __inv__(self):
        """
        Calculate inverse in group
        """
        resultSW = -self.castTo("ShortWeierstrassPoint")
        return self.castFrom(resultSW)
    
    def discreteLog(self, basePoint):
        """
        Used to find the multiplicator m where m*basePoint = self
        """
        selfSW = self.castTo("ShortWeierstrassPoint")
        basePointSW = basePoint.castTo("ShortWeierstrassPoint")
        return selfSW.discreteLog(basePointSW)

    def genMultiples(self, nDigits):
        """
        Generates an array 
        [   
           [e, 1*self, 2*1*self,\dots, (b-1)*1*self],
           [e, b*self, 2*b*self,\dots, (b-1)*b*self],
           [e, (b^2)*self, 2*(b^2)*self,\dots, (b-1)*(b^2)*self],
           \dots,
           [e, (b^{l-1})*self, 2*(b^{l-1})*self,\dots, (b-1)*(b^{n-1})*self]
        ]
        Where b is the base used.
        """
        multiples = []
        for i in range(0, nDigits):
            multipleSelf = self * (TE_ENC_BASE**i)
            multiples_i = []
            for j in range(0, TE_ENC_BASE):
                multiples_i.append(multipleSelf*j)
            multiples.append(multiples_i)
        return multiples

    @classmethod
    def getInfinity(cls, curveParams: list, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

        
    def castTo(self, cls: Type):
        """
        Cast self to the type specified by cls
        """
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFrom(self, other):
        """
        Cast other to the same type as self
        """
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def toJSON(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def __str__(self):
        return str(self.toJSON())

    def getGenerator(self, name=None):
        """
        Generates a random generator of the elliptic curve subgroup (If this subgroup has prime order.)
        """
        pointSW = self.castTo("ShortWeierstrassPoint")
        return self.castFrom(pointSW.getGenerator(name=name))

    def getRandomPoint(self, name=None):
        """
        Generates a random point in the elliptic curve subgroup (not infty)
        """
        pointSW = self.castTo("ShortWeierstrassPoint")
        return self.castFrom(pointSW.getGenerator(name=name))

    def castTo(self, clsString: Type):
        if clsString == "ShortWeierstrassPoint":
            return self.castToShortWeierstrassPoint()
        elif clclsStrings == "MontgomeryProjectivePoint":
            return self.castToMontgomeryProjectivePoint()
        elif clsString == "MontgomeryAffinePoint":
            return self.castToMontgomeryAffinePoint()
        elif clsString == "TwistedEdwardsPoint":
            return self.castToTwistedEdwardsPoint()
        else:
            raise NotImplementedError(f"Conversion from {str(type(self))} to {str(cls)} not implemented.")

    def castFrom(self, other):
        typeName = type(other).__name__  # Get class name as a string
        if typeName == "ShortWeierstrassPoint":
            return self.castFromShortWeierstrassPoint(other)
        elif typeName == "MontgomeryProjectivePoint":
            return self.castFromMontgomeryProjectivePoint(other)
        elif typeName == "MontgomeryAffinePoint":
            return self.castFromMontgomeryAffinePoint(other)
        elif typeName == "TwistedEdwardsPoint":
            return self.castFromTwistedEdwardsPoint(other)
        else:
            raise NotImplementedError(f"Conversion from {typeName} to {type(self).__name__} not implemented.")

    def castToShortWeierstrassPoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castToMontgomeryProjectivePoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castToMontgomeryAffinePoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castToTwistedEdwardsPoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")


    def castFromShortWeierstrassPoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFromMontgomeryProjectivePoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFromMontgomeryAffinePoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFromTwistedEdwardsPoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")
