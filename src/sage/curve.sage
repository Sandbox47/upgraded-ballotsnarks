from sageImport import sage_import
sage_import('constants', fromlist=['BASE_FIELD', 'PLAINTEXT_LIMIT', 'CURVE_CHOSEN_SUBGROUP_ORDER', 'MONTGOMERY_CURVE_A', 'MONTGOMERY_CURVE_B'])

class MontgomeryCurvePoint():
    def __init__(self, x: BASE_FIELD, y: BASE_FIELD, notInfty: bool, name=None):
        self.x = x
        self.y = y
        self.notInfty = notInfty
        self.name = name

class MontgomeryCurve():
    # INITIALIZATION:
    def __init__(self, A=MONTGOMERY_CURVE_A, B=MONTGOMERY_CURVE_B, chosenSubgroupOrder=CURVE_CHOSEN_SUBGROUP_ORDER):
        # Montgomery parameters
        self.A = BASE_FIELD(A)
        self.B = BASE_FIELD(B)
        self.chosenSubGroupOrder = CURVE_CHOSEN_SUBGROUP_ORDER
        self.computeWeierstrassParameters()
        self.computeShortWeierstrassToMontgomeryParameters()
        self.groupOrder = self.E.order()

    def computeWeierstrassParameters(self):
        # Parameters (calculated from montgomery equation) (according to MoonMathManual, 
        # 5.2 Montgomery curves):
        self.a = (BASE_FIELD(3)-self.A**2)/(BASE_FIELD(3)*self.B**2)
        self.b = (BASE_FIELD(2)*self.A**3-BASE_FIELD(9)*self.A)/(BASE_FIELD(27)*self.B**3)
        # Define the elliptic curve
        self.E = EllipticCurve([self.a, self.b])

    def computeShortWeierstrassToMontgomeryParameters(self):
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
        self.alpha = alpha
        self.s = s

    def __eq__(self, other):
        return self.A == other.A and self.B == other.B

    def __str__(self):
        return "{(x,y)|" + f"{A}*y^2=x^3+{B}*x^2+x" + "} and O (infinity)"

    # TRANSFORMATIONS:
    # Montgomery to Weierstrass: M_{A, B} -> E_{a,b}
    def montgomeryToShortWeierstrass(self, p: MontgomeryCurvePoint):
        """
        Map a point from Montgomery form to Weierstrass form.
        """
        if p.notInfty:
            return self.E.point([p.x/self.B + self.A/(3*self.B), p.y/self.B])
        else:
            return self.E(0) # Infinity

    
    def shortWeierstrassToMontgomery(self, p):
        """
        Map a point from Weierstrass form to Montgomery form.
        """
        pM = None
        if p != self.E(0):
            pM = MontgomeryCurvePoint(self.s * (p[0] - self.alpha), self.s * p[1], True)
        else:
            pM = MontgomeryCurvePoint(0, 0, False)

        return pM

    # Will return the result as a Montgomery Curve Point
    def addPoints(self, first, second):
        if not self.isPointOnCurve(first) or not self.isPointOnCurve(second):
            raise ValueError("One of the given points is not on the curve.")
        firstSW = self.montgomeryToShortWeierstrass(first)
        secondSW = self.montgomeryToShortWeierstrass(second)
        result = firstSW + secondSW
        pointM = self.shortWeierstrassToMontgomery(result)
        return pointM

    def scalarMul(self, point: MontgomeryCurvePoint, multiplier: BASE_FIELD):
        if not self.isPointOnCurve(point):
            raise ValueError("The given points is not on the curve.")
        pointSW = self.montgomeryToShortWeierstrass(point)
        result = multiplier * pointSW
        pointM = self.shortWeierstrassToMontgomery(result)
        return pointM

    def invert(self, point: MontgomeryCurvePoint):
        if not self.isPointOnCurve(point):
            raise ValueError("The given points is not on the curve.")
        pointSW = self.montgomeryToShortWeierstrass(point)
        result = -pointSW
        pointM = self.shortWeierstrassToMontgomery(result)
        return pointM

    def discreteLog(self, point: MontgomeryCurvePoint, basePoint: MontgomeryCurvePoint):
        if not self.isPointOnCurve(point) or not self.isPointOnCurve(basePoint):
            raise ValueError("One of the given points is not on the curve.")
        pointSW = self.montgomeryToShortWeierstrass(point)
        basePointSW = self.montgomeryToShortWeierstrass(basePoint)
        multiplier = 0
        while multiplier*basePointSW != pointSW and multiplier <= PLAINTEXT_LIMIT:
            multiplier += 1
        if multiplier*basePointSW == pointSW:
            return multiplier
        raise ArithmeticError(f"The given point is not a multiple within the allowed range [0, {PLAINTEXT_LIMIT}] of the given basePoint.")

    # TODO: Check subgroup membership (maybe via cofactor clearing?)
    def isPointOnCurve(self, point: MontgomeryCurvePoint):
        if not point.notInfty or self.B*point.y^2 == point.x^3 + self.A*point.x^2 + point.x:
            return True
        else:
            return False   

    def getGenerator(self, name=None):
        """
        Generates a random generator of the elliptic curve subgroup (If this subgroup has prime order.)
        """
        pointM = None
        while pointM == None or not pointM.notInfty:
            pointM = self.getRandomPoint(name)
        return pointM

    def getRandomPoint(self, name=None):
        """
        Generates a random point in the elliptic curve subgroup (not infty)
        """
        pointSW = self.E.random_point()
        pointM = self.shortWeierstrassToMontgomery(pointSW)
        pointM = self.cofactorClearing(pointM)
        pointM.name = name
        return pointM

    def cofactorClearing(self, point: MontgomeryCurvePoint):
        """
        Computes point * (curveOrder // chosenSubgroupOrder)
        If this is not infty (neutral element), the point is a generator of the subgroup. Otherwise, it is not a generator of the subgroup.
        """
        return self.scalarMul(point, self.groupOrder // self.chosenSubGroupOrder)
