from sageImport import sage_import
from typing import Type
import json
from JSON import JSONUtils
sage_import('../constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'MONTGOMERY_CURVE_A', 'MONTGOMERY_CURVE_B', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])
sage_import('curve', fromlist=['CurvePoint'])
sage_import('ShortWeierstrass', fromlist=['ShortWeierstrassPoint'])

class MontgomeryPoint(CurvePoint):
    def __init__(self, coordinates: list, A: BASE_FIELD=MONTGOMERY_CURVE_A, B: BASE_FIELD=MONTGOMERY_CURVE_B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        super().__init__(coordinates, [A, B], chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=name)
        self.A = BASE_FIELD(A)
        self.B = BASE_FIELD(B)

    def castFromShortWeierstrassParameters(self, other):
        # According to MoonMathManual, Section 5.2
        # Weierstrass to Montgomery: E_{a,b} -> M_{A, B}
        # Define the cubic equation z^3 + az + b = 0 and find roots
        R.<z> = PolynomialRing(BASE_FIELD)
        cubic = z^3 + other.a*z + other.b
        roots = cubic.roots()

        # Ensure the cubic equation has at least one root
        if not roots:
            raise ValueError("The cubic equation z^3 + az + b = 0 has no roots in F.")

        # Pick the first root alpha (or choose based on your application)
        alpha = roots[0][0]

        # Check if 3*alpha^2 + a is a quadratic residue
        quad_residue = 3*alpha^2 + other.a
        if not quad_residue.is_square():
            raise ValueError("3*alpha^2 + a is not a quadratic residue in F.")

        # Compute s = 1 / sqrt(3*alpha^2 + a)
        s = 1 / quad_residue.sqrt()

        return alpha, s

    def castToShortWeierstrassParameters(self):
        # Parameters (calculated from montgomery equation) (according to MoonMathManual, 
        # 5.2 Montgomery curves):
        a = (BASE_FIELD(3)-self.A**2)/(BASE_FIELD(3)*self.B**2)
        b = (BASE_FIELD(2)*self.A**3-BASE_FIELD(9)*self.A)/(BASE_FIELD(27)*self.B**3)
        return a, b

class MontgomeryAffinePoint(MontgomeryPoint):
    def __init__(self, x:BASE_FIELD, y:BASE_FIELD, notInfty:bool, A: BASE_FIELD=MONTGOMERY_CURVE_A, B: BASE_FIELD=MONTGOMERY_CURVE_B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        super().__init__([x, y, notInfty], A, B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=name)
        self.x = BASE_FIELD(x)
        self.y = BASE_FIELD(y)
        self.notInfty = notInfty

    @classmethod
    def getInfinity(cls, curveParams: list=None, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        if curveParams == None:
            return MontgomeryAffinePoint(0, 0, False, chosenSubgroupOrder=chosenSubgroupOrder, name=name)
        if len(curveParams) != 2:
            raise AttributeError(f"You provided {len(curveParams)} curve parameters but {2} are required")
        return MontgomeryAffinePoint(0, 0, False, curveParams[0], curveParams[1], chosenSubgroupOrder=chosenSubgroupOrder, name=name)

    def toJSON(self):
        innerData = {
            "x": str(self.x),
            "y": str(self.y),
            "notInfty": str(int(self.notInfty))  # Convert boolean to 1 or 0 string
        }
        return JSONUtils.toJSON(self, innerData)
    
    def castToShortWeierstrassPoint(self):
        """
        Map a point from Montgomery form to Weierstrass form. (MoonMathManual, Section 5.2)
        """
        a, b = self.castToShortWeierstrassParameters()
        if self.notInfty:
            return ShortWeierstrassPoint(self.x/self.B + self.A/(3*self.B), self.y/self.B, True, a, b, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name)
        else:
            return ShortWeierstrassPoint(0, 0, False, a, b, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name) # Infinity

    def castToMontgomeryProjectivePoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castToTwistedEdwardsPoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")


    def castFromShortWeierstrassPoint(self, other):
        """
        Map a point from Weierstrass form to Montgomery form. (MoonMathManual, Section 5.2)
        """
        alpha, s = self.castFromShortWeierstrassParameters(other)
        A = 3*alpha*s
        B = s
        otherM = None
        if other.toSage() != other.sageCurve(0): # Not infinity
            return MontgomeryAffinePoint(s * (other.x - alpha), s * other.y, True, A, B, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)
        else:
            return MontgomeryAffinePoint(0, 0, False, A, B, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)

    def castFromMontgomeryProjectivePoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

    def castFromTwistedEdwardsPoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")


class MontgomeryProjectivePoint(MontgomeryPoint):
    def __init__(self, X:BASE_FIELD, Y:BASE_FIELD, Z:BASE_FIELD, A: BASE_FIELD=MONTGOMERY_CURVE_A, B: BASE_FIELD=MONTGOMERY_CURVE_B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        super().__init__([X, Y, Z], A, B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=name)
        self.X = BASE_FIELD(X)
        self.Y = BASE_FIELD(Y)
        self.Z = BASE_FIELD(Z)

    @classmethod
    def getInfinity(cls, curveParams: list=None, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        if curveParams == None:
            return MontgomeryProjectivePoint(0, 1, 0, chosenSubgroupOrder=chosenSubgroupOrder, name=name)
        if len(curveParams) != 2:
            raise AttributeError(f"You provided {len(curveParams)} curve parameters but {2} are required")
        return MontgomeryProjectivePoint(0, 1, 0, curveParams[0], curveParams[1], chosenSubgroupOrder=chosenSubgroupOrder, name=name)

    def toJSON(self):
        innerData = {
            "X": str(self.X),
            "Y": str(self.Y),
            "Z": str(self.Z)
        }
        return JSONUtils.toJSON(self, innerData)

    def castToShortWeierstrassPoint(self):
        selfAffine = self.castToMontgomeryAffinePoint()
        return selfAffine.castToShortWeierstrassPoint()

    def castToMontgomeryAffinePoint(self):
        if self.Z != 0:  # Not infinity
            return MontgomeryAffinePoint(self.X, self.Y, True, self.A, self.B, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name)
        else:
            return MontgomeryAffinePoint(0, 0, False, self.A, self.B, chosenSubgroupOrder=self.chosenSubgroupOrder, name=self.name)

    def castToTwistedEdwardsPoint(self):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")


    def castFromShortWeierstrassPoint(self, other):
        otherAffine = self.castToMontgomeryAffinePoint().castFromShortWeierstrassPoint(other)
        return self.castFromMontgomeryAffinePoint(otherAffine)

    def castFromMontgomeryAffinePoint(self, other):
        if other.notInfty:
            return MontgomeryProjectivePoint(other.x, other.y, 1, self.A, self.B, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)
        else:
            return MontgomeryProjectivePoint(0, 1, 0, self.A, self.B, chosenSubgroupOrder=other.chosenSubgroupOrder, name=other.name)

    def castFromTwistedEdwardsPoint(self, other):
        raise NotImplementedError("Behaviour needs to be implemented in specific subclass.")

