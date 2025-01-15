from sageImport import sage_import
sage_import('constants', fromlist=['BASE_FIELD', 'BASE_FIELD_P'])
sage_import('curve', fromlist=['MontgomeryCurve'])

class CurvePoint():
    def __init__(self, curve: MontgomeryCurve, name=None):
        self.curve = curve
        self.name = name

    def __add__(self, other):
        curvesMatch = self.curve == other.curve
        sameType = type(self) == type(other)
        if curvesMatch and sameType:
            selfM = self.toMontgomery()
            otherM = other.toMontgomery()
            sumM = self.curve.addPoints(selfM, otherM)
            return self.fromMontgomery(sumM, self.curve)
        else:
            if not sameType:
                raise TypeError("Trying to add two points of different types: " + str(type(self)) + ", " + str(type(other)) + ".")
            if not curvesMatch:
                raise ValueError("Curves of the points to be added don't match.")

    # Used for scalar multiplication
    def __mul__(self, multiplier):
        # if isinstance(multiplier, sage.rings.integer.Integer) and 0 <= multiplier < BASE_FIELD_P:
        selfM = self.toMontgomery()
        mulM = self.curve.scalarMul(selfM, multiplier)
        return self.fromMontgomery(mulM, self.curve)
        # else:
        #     raise NotImplementedError("Multiplication with object of type " + str(type(multiplier)) + " not implemented.")

    def __rmul__(self, multiplier):
        return self.__mul__(multiplier)

    def __inv__(self):
        selfM = self.toMontgomery()
        invM = self.curve.invert(selfM)
        return self.fromMontgomery(invM, self.curve)

    def discreteLog(self, basePoint):
        curvesMatch = self.curve == basePoint.curve
        sameType = type(self) == type(basePoint)
        if curvesMatch and sameType:
            selfM = self.toMontgomery()
            basePointM = basePoint.toMontgomery()
            return self.curve.discreteLog(selfM, basePointM)
        else:
            if not sameType:
                raise TypeError("Type of point and basePoint do not match: " + str(type(self)) + ", " + str(type(other)) + ".")
            if not curvesMatch:
                raise ValueError("Curves of point and basePoint don't match.")

    def montgomeryToCurvePoint(self):
        raise NotImplementedError()

    def toMontgomery(self, point):
        raise NotImplementedError()