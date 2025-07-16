from sageImport import sage_import
from typing import Type
sage_import('../constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'MONTGOMERY_CURVE_A', 'MONTGOMERY_CURVE_B', 'TE_ENC_BASE', 'DIGITS_RAND', 'DIGITS_PLAIN'])
sage_import('curve', fromlist=['CurvePoint'])

class ShortWeierstrassPoint(CurvePoint):
    def __init__(self, x: BASE_FIELD, y: BASE_FIELD, notInfty: bool, a: BASE_FIELD, b: BASE_FIELD, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        super().__init__([x,y,notInfty], [a,b], chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=name)
        self.a = BASE_FIELD(a)
        self.b = BASE_FIELD(b)
        self.x = BASE_FIELD(x)
        self.y = BASE_FIELD(y)
        self.notInfty = notInfty        

        self.sageCurve = EllipticCurve([self.a, self.b])

    @classmethod
    def getInfinity(cls, curveParams: list, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER, name=None):
        if len(curveParams) != 2:
            raise AttributeError(f"You provided {len(curveParams)} curve parameters but {2} are required")
        return ShortWeierstrassPoint(0, 0, False, curveParams[0], curveParams[1], chosenSubgroupOrder=chosenSubgroupOrder, name=name)

    def toSage(self):
        """
        Convert to representation with preimplemented sage elliptic curve
        """
        if self.notInfty:
            return self.sageCurve.point([self.x, self.y])
        else:
            return self.sageCurve.point(0)

    def fromSage(self, point, name=None):
        """
        Convert from representation with preimplemented sage elliptic curve to this class
        """
        if point != self.sageCurve(0): # Point is not infinity
            return ShortWeierstrassPoint(point[0], point[1], True, self.a, self.b, name=name)
        else:
            return ShortWeierstrassPoint(0, 0, False, self.a, self.b, name=name)


    def isCompatible(self, other):
        return self.a == other.a and self.b == other.b

    def __add__(self, other):
        """
        Used to execute the group law
        """
        if self.isCompatible(other):
            resultSage = self.toSage() + other.toSage()
            return self.fromSage(resultSage)
        else:
            raise ValueError("Points are not from the same curve.")

    def __mul__(self, multiplier):
        """
        Scalar multiplication
        """
        resultSage = multiplier * self.toSage()
        return self.fromSage(resultSage)

    def __rmul__(self, multiplier):
        return self.__mul__(multiplier)

    def __inv__(self):
        """
        Calculate inverse in group
        """
        resultSage = -self.toSage()
        return self.fromSage(resultSage)
    
    def discreteLog(self, basePoint):
        """
        Used to find the multiplicator m where m*basePoint = self
        """
        if self.isCompatible(other):
            selfSage = self.toSage()
            basePointSage = basePoint.toSage()
            multiplier = 0
            while multiplier*basePointSage != selfSage and multiplier <= PLAINTEXT_LIMIT:
                multiplier += 1
            if multiplier*basePointSW == pointSW:
                return multiplier
            raise ArithmeticError(f"This point is not a multiple within the allowed range [0, {PLAINTEXT_LIMIT}] of the given basePoint.")
        else:
            raise ValueError("Point and basepoint are not from the same curve.")

    def getGenerator(self, name=None):
        """
        Generates a random generator of the elliptic curve subgroup (If this subgroup has prime order.)
        """
        point = None
        while point == None or not point.notInfty:
            point = self.getRandomPoint(name)
        return point

    def getRandomPoint(self, name=None):
        """
        Generates a random point in the elliptic curve subgroup (not infty)
        """
        pointSage = self.sageCurve.random_point()
        point = self.fromSage(pointSage)
        point = point.cofactorClearing()
        point.name = name
        return point

    def cofactorClearing(self):
        """
        Computes point * (curveOrder // chosenSubgroupOrder)
        If this is not infty (neutral element), the point is a generator of the subgroup. Otherwise, it is not a generator of the subgroup.
        """
        groupOrder = self.sageCurve.order()
        return self * (groupOrder // self.chosenSubgroupOrder)

    def castToMontgomeryParamters(self):
        # Weierstrass to Montgomery: E_{a,b} -> M_{A, B}
        # Define the cubic equation z^3 + az + b = 0 and find roots
        R.<z> = PolynomialRing(BASE_FIELD)
        cubic = z^3 + self.a*z + self.b
        roots = cubic.roots()

        # Ensure the cubic equation has at least one root
        if not roots:
            raise ValueError("The cubic equation z^3 + az + b = 0 has no roots in F.")

        # Pick the first root alpha (or choose based on your application)
        alpha = roots[0][0]

        # Check if 3*alpha^2 + a is a quadratic residue
        quad_residue = 3*alpha^2 + self.a
        if not quad_residue.is_square():
            raise ValueError("3*alpha^2 + a is not a quadratic residue in F.")

        # Compute s = 1 / sqrt(3*alpha^2 + a)
        s = 1 / quad_residue.sqrt()

        return alpha, s

    def castToMontgomeryProjectivePoint(self):
        """
        Map a point from Weierstrass form to Montgomery form.
        """
        selfM = None
        if self != self.sageCurve(0):
            selfM = MontgomeryCurvePoint(self.s * (p[0] - self.alpha), self.s * p[1], True)
        else:
            selfM = MontgomeryCurvePoint(0, 0, False)

        return selfM