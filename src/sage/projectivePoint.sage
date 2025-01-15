from sageImport import sage_import
import json
sage_import('constants', fromlist=['BASE_FIELD'])
sage_import('curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('curvePoint', fromlist=['CurvePoint'])

class ProjectivePoint(CurvePoint):
    def __init__(self, X: BASE_FIELD, Y: BASE_FIELD, Z: BASE_FIELD, curve: MontgomeryCurve, name=None):
        super().__init__(curve, name)
        self.X = X
        self.Y = Y
        self.Z = Z

    def __str__(self):
        return f"({self.X}:{self.Y}:{self.Z})"

    def toJSON(self):
        # Convert the attributes to the correct format
        innerData = {
                "X": str(self.X),
                "Y": str(self.Y),
                "Z": str(self.Z)
        }
        data = None
        if self.name == None:
            data = innerData
        else:
            data = {
                self.name: innerData
            }
        
        return data

    def toMontgomery(self):
        if self.Z != 0:
            return MontgomeryCurvePoint(self.X/self.Z, self.Y/self.Z, 1, self.name)
        else:
            return MontgomeryCurvePoint(0, 0, 1, self.name)

    def montgomeryToCurvePoint(self, point: MontgomeryCurvePoint):
        return ProjectivPoint.fromMontgomery(point, self.name)

    @classmethod
    def fromMontgomery(cls, point: MontgomeryCurvePoint, curve: MontgomeryCurve):
        if point.notInfty:
            return ProjectivePoint(point.x, point.y, 1, curve, point.name)
        else:
            return ProjectivePoint(0, 1, 0, curve, point.name)

    @classmethod
    def getRandomPoint(cls, curve: MontgomeryCurve, name=None):
        pointM = curve.getRandomPoint(name)
        point = ProjectivePoint.fromMontgomery(pointM, curve)
        point.curve = curve
        return point
        
