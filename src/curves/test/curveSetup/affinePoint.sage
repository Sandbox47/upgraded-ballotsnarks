from sageImport import sage_import
import json
sage_import('constants', fromlist=['BASE_FIELD'])
sage_import('curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('curvePoint', fromlist=['CurvePoint'])

class AffinePoint(CurvePoint):
    def __init__(self, x: BASE_FIELD, y: BASE_FIELD, notInfty: bool, curve: MontgomeryCurve, name=None):
        super().__init__(curve, name)
        self.x = x
        self.y = y
        self.notInfty = notInfty

    def __str__(self):
        if self.notInfty:
            return f"({self.x}, {self.y})"
        else:
            return "O (Infinity)"

    def toJSON(self):
        # Convert the attributes to the correct format
        innerData = {
                "x": str(self.x),
                "y": str(self.y),
                "notInfty": str(int(self.notInfty))  # Convert boolean to 1 or 0 string
        }
        data = None
        if self.name == None:
            data = innerData
        else:
            data = {
                self.name: innerData
            }
        
        return json.dumps(data)

    def toMontgomery(self):
        return MontgomeryCurvePoint(self.x, self.y, self.notInfty, self.name)

    def montgomeryToCurvePoint(self, point: MontgomeryCurvePoint):
        return AffinePoint.fromMontgomery(point, self.curve)

    @classmethod
    def fromMontgomery(cls, point: MontgomeryCurvePoint, curve: MontgomeryCurve):
        return AffinePoint(point.x, point.y, point.notInfty, curve, point.name)
    
    @classmethod
    def getRandomPoint(cls, curve: MontgomeryCurve, name=None):
        pointM = curve.getRandomPoint(name)
        point = AffinePoint.fromMontgomery(pointM, curve)
        point.curve = curve
        return point


