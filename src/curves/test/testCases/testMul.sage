from sageImport import sage_import
from JSON import JSONUtils
sage_import('../curveSetup/curve', fromlist=['MontgomeryCurve', 'MontgomeryCurvePoint'])
sage_import('../curveSetup/affinePoint', fromlist=['AffinePoint'])
sage_import('../curveSetup/projectivePoint', fromlist=['ProjectivePoint'])

def testMulAffine(multiplier):
    curve = MontgomeryCurve()
    point = AffinePoint.getRandomPoint(curve, "P")

    mPoint = multiplier * point
    mPoint.name = "test"

    print(f"P = {point}")
    print(f"mP = {mPoint}")

    JSONUtils.combineAndExport([point, {"m": int(multiplier)}, mPoint])

def testMulProjective(multiplier):
    curve = MontgomeryCurve()
    point = ProjectivePoint.getRandomPoint(curve, "P")

    mPoint = multiplier * point
    mPoint.name = "test"

    print(f"P = {point}")
    print(f"mP = {mPoint}")

    JSONUtils.combineAndExport([point, {"m": int(multiplier)}, mPoint])

testMulAffine(8374621)