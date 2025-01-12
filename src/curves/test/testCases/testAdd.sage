from sageImport import sage_import
from JSON import JSONUtils
sage_import('../curveSetup/curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('../curveSetup/affinePoint', fromlist=['AffinePoint'])
sage_import('../curveSetup/projectivePoint', fromlist=['ProjectivePoint'])

def testAddAffine():
    curve = MontgomeryCurve()
    point1 = AffinePoint.getRandomPoint(curve, "p")
    point2 = AffinePoint.getRandomPoint(curve, "q")

    pointSum = point1 + point2
    pointSum.name = "test"

    print(f"p = {point1}")
    print(f"q = {point2}")
    print(f"p + q = {pointSum}")

    JSONUtils.combineAndExport([point1, point2, pointSum])

def testAddProjective():
    curve = MontgomeryCurve()
    point1 = ProjectivePoint.getRandomPoint(curve, "P")
    print(point1.name)
    point2 = ProjectivePoint.getRandomPoint(curve, "Q")
    print(point2.name)

    pointSum = point1 + point2
    pointSum.name = "test"

    print(f"P = {point1}")
    print(f"Q = {point2}")
    print(f"P + Q = {pointSum}")

    JSONUtils.combineAndExport([point1, point2, pointSum])

# testAddProjective()
testAddAffine()